## C# からこのRailsアプリへユーザー登録/ログイン/アップロード/ダウンロード/ログアウトする例

このアプリは通常のRailsコントローラ（CSRF保護あり・Cookieセッション）で動作します。C#から操作する場合は、
- Cookie を維持（CookieContainer）
- CSRFトークンを取得して送信（authenticity_token もしくは X-CSRF-Token）
- アップロードは multipart/form-data で送信（`xml_document[xml_file]` などネストしたキー名）
を行います。

以下は .NET 6 以降の C# コンソールアプリ想定のサンプルです。

### 準備: HttpClient と CSRF トークン取得

```csharp
using System;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

public class RailsClient : IDisposable
{
	private readonly Uri _baseUri;
	private readonly CookieContainer _cookies = new CookieContainer();
	// リダイレクトを追わずに Location を取得したいので false にしています（必要に応じて true でも可）
	private readonly HttpClient _http;

	public RailsClient(string baseUrl)
	{
		_baseUri = new Uri(baseUrl.TrimEnd('/') + "/");
		var handler = new HttpClientHandler
		{
			CookieContainer = _cookies,
			AllowAutoRedirect = false,
			UseCookies = true,
		};
		_http = new HttpClient(handler) { BaseAddress = _baseUri };
	}

	public void Dispose() => _http.Dispose();

	// レイアウトの <meta name="csrf-token" content="..."> から取得
	public async Task<string> GetCsrfTokenAsync(string path = "")
	{
		var res = await _http.GetAsync(path);
		res.EnsureSuccessStatusCode();
		var html = await res.Content.ReadAsStringAsync();
		var m = Regex.Match(html, "<meta name=\\\"csrf-token\\\" content=\\\"(?<t>[^\\\"]+)\\\"/?>", RegexOptions.IgnoreCase);
		if (!m.Success) throw new InvalidOperationException("CSRF token not found");
		return m.Groups["t"].Value;
	}

	private static FormUrlEncodedContent Form(params (string key, string value)[] items)
	{
		var list = new System.Collections.Generic.List<System.Collections.Generic.KeyValuePair<string, string>>();
		foreach (var (k, v) in items) list.Add(new(k, v));
		return new FormUrlEncodedContent(list);
	}
}
```

### 1) ユーザー登録（/signup）

Rails の UsersController#create は `params.require(:user)` を期待します。フォーム形式では `user[email]` のようなネストキーで送信します。

```csharp
public async Task SignupAsync(string email, string password)
{
	var csrf = await GetCsrfTokenAsync("signup"); // もしくは "/" 等、どのGETでもOK

	var content = new FormUrlEncodedContent(new[]
	{
		new KeyValuePair<string, string>("authenticity_token", csrf),
		new KeyValuePair<string, string>("user[email]", email),
		new KeyValuePair<string, string>("user[password]", password),
		new KeyValuePair<string, string>("user[password_confirmation]", password),
	});

	var req = new HttpRequestMessage(HttpMethod.Post, "signup") { Content = content };
	req.Headers.Add("X-CSRF-Token", csrf); // 念のためヘッダでも送信
	var res = await _http.SendAsync(req);

	if (res.StatusCode == HttpStatusCode.Found) { /* 302 想定: サインアップ成功 */ }
	else if (!res.IsSuccessStatusCode)
	{
		var body = await res.Content.ReadAsStringAsync();
		throw new Exception($"Signup failed: {(int)res.StatusCode} {res.ReasonPhrase}\n{body}");
	}
}
```

### 2) ログイン（/login）

SessionsController#create はトップレベルに `email`, `password`, `remember_me` を期待します。

```csharp
public async Task LoginAsync(string email, string password, bool rememberMe = true)
{
	var csrf = await GetCsrfTokenAsync("login");

	var content = new FormUrlEncodedContent(new[]
	{
		new KeyValuePair<string, string>("authenticity_token", csrf),
		new KeyValuePair<string, string>("email", email),
		new KeyValuePair<string, string>("password", password),
		new KeyValuePair<string, string>("remember_me", rememberMe ? "1" : "0"),
	});

	var req = new HttpRequestMessage(HttpMethod.Post, "login") { Content = content };
	req.Headers.Add("X-CSRF-Token", csrf);
	var res = await _http.SendAsync(req);

	if (res.StatusCode != HttpStatusCode.Found && res.StatusCode != HttpStatusCode.OK)
	{
		var body = await res.Content.ReadAsStringAsync();
		throw new Exception($"Login failed: {(int)res.StatusCode} {res.ReasonPhrase}\n{body}");
	}
}
```

### 3) XMLファイルのアップロード（/xml_documents）

XmlDocumentsController#create は `params.require(:xml_document)` を期待します。multipart/form-data で、
`xml_document[title]`, `xml_document[description]`, `xml_document[xml_file]` を送ります。成功時は 302 で `/xml_documents/:id` にリダイレクトされます。

```csharp
public async Task<int> UploadXmlAsync(string filePath, string title, string? description = null)
{
	var csrf = await GetCsrfTokenAsync("xml_documents/new");

	using var form = new MultipartFormDataContent();
	form.Add(new StringContent(csrf), "authenticity_token");
	form.Add(new StringContent(title), "xml_document[title]");
	if (!string.IsNullOrEmpty(description))
		form.Add(new StringContent(description!), "xml_document[description]");

	var fileBytes = await File.ReadAllBytesAsync(filePath);
	var fileContent = new ByteArrayContent(fileBytes);
	fileContent.Headers.ContentType = new MediaTypeHeaderValue("text/xml");
	form.Add(fileContent, "xml_document[xml_file]", Path.GetFileName(filePath));

	var req = new HttpRequestMessage(HttpMethod.Post, "xml_documents") { Content = form };
	req.Headers.Add("X-CSRF-Token", csrf);
	var res = await _http.SendAsync(req);

	// 成功時は 302 Found で Location: /xml_documents/:id
	if (res.StatusCode != HttpStatusCode.Found)
	{
		var body = await res.Content.ReadAsStringAsync();
		throw new Exception($"Upload failed: {(int)res.StatusCode} {res.ReasonPhrase}\n{body}");
	}

	var location = res.Headers.Location?.ToString() ?? string.Empty;
	var m = Regex.Match(location, @"/xml_documents/(?<id>\d+)");
	if (!m.Success) throw new Exception($"Unexpected Location header: {location}");
	return int.Parse(m.Groups["id"].Value);
}
```

### 4) ダウンロード（/xml_documents/:id/download）

ダウンロードは GET でOK（ログイン必須ではありません）。取得したバイト列をローカルへ保存します。

```csharp
public async Task DownloadXmlAsync(int id, string saveAsPath)
{
	var res = await _http.GetAsync($"xml_documents/{id}/download");
	res.EnsureSuccessStatusCode();
	var bytes = await res.Content.ReadAsByteArrayAsync();
	await File.WriteAllBytesAsync(saveAsPath, bytes);
}
```

### 5) ログアウト（DELETE /logout）

Rails のルートは DELETE メソッドで `/logout`。CSRFトークンをヘッダに付けて送ります。

```csharp
public async Task LogoutAsync()
{
	var csrf = await GetCsrfTokenAsync(); // 任意のGETでOK
	var req = new HttpRequestMessage(HttpMethod.Delete, "logout");
	req.Headers.Add("X-CSRF-Token", csrf);
	var res = await _http.SendAsync(req);
	if (res.StatusCode != HttpStatusCode.Found && res.StatusCode != HttpStatusCode.OK)
	{
		var body = await res.Content.ReadAsStringAsync();
		throw new Exception($"Logout failed: {(int)res.StatusCode} {res.ReasonPhrase}\n{body}");
	}
}
```

### 一連の流れ（例）

```csharp
public static async Task Main()
{
	using var client = new RailsClient("http://127.0.0.1:3000");

	await client.SignupAsync("user@example.com", "Passw0rd!");
	await client.LoginAsync("user@example.com", "Passw0rd!", rememberMe: true);

	int id = await client.UploadXmlAsync("./sample.xml", title: "sample", description: null);
	await client.DownloadXmlAsync(id, "./downloaded_sample.xml");

	await client.LogoutAsync();
}
```

補足
- このアプリの通常コントローラはCSRF保護が有効です。非ブラウザクライアントからは、先にGETでCSRFトークンを取得し、POST/DELETEにトークンを付与してください。
- 302（Found）は正常系です（サインアップ/ログイン/アップロード/ログアウト時）。Locationヘッダから遷移先を取得できます。
- MIMEタイプは text/xml を指定しています。必要に応じて application/xml でも動作します。

# .NET Framework 4.8向け

- using var → using (...) { ... } に置換
- タプル/ターゲット型new →明示的な型で記述
- File.ReadAllBytesAsync → File.ReadAllBytes（4.8はasync版なし）
- async Mainが無い場合 → Mainで.GetAwaiter().GetResult()を使う
- 必要なら TLS 1.2 を有効化: ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;

```csharp
using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

public class RailsClient : IDisposable
{
  private readonly HttpClient _http;

  public RailsClient(string baseUrl)
  {
    var handler = new HttpClientHandler {
      CookieContainer = new CookieContainer(),
      AllowAutoRedirect = false,
      UseCookies = true
    };
    _http = new HttpClient(handler) { BaseAddress = new Uri(baseUrl.TrimEnd('/') + "/") };
  }

  public void Dispose() { _http.Dispose(); }

  public async Task<string> GetCsrfTokenAsync(string path = "")
  {
    var res = await _http.GetAsync(path);
    res.EnsureSuccessStatusCode();
    var html = await res.Content.ReadAsStringAsync();
    var m = Regex.Match(html, "<meta name=\\\"csrf-token\\\" content=\\\"(?<t>[^\\\"]+)\\\"/?>", RegexOptions.IgnoreCase);
    if (!m.Success) throw new InvalidOperationException("CSRF token not found");
    return m.Groups["t"].Value;
  }

  public async Task SignupAsync(string email, string password)
  {
    var csrf = await GetCsrfTokenAsync("signup");
    var pairs = new List<KeyValuePair<string,string>> {
      new KeyValuePair<string,string>("authenticity_token", csrf),
      new KeyValuePair<string,string>("user[email]", email),
      new KeyValuePair<string,string>("user[password]", password),
      new KeyValuePair<string,string>("user[password_confirmation]", password),
    };
    var req = new HttpRequestMessage(HttpMethod.Post, "signup") { Content = new FormUrlEncodedContent(pairs) };
    req.Headers.Add("X-CSRF-Token", csrf);
    var res = await _http.SendAsync(req);
    if (res.StatusCode != HttpStatusCode.Found && !res.IsSuccessStatusCode)
      throw new Exception("Signup failed");
  }

  public async Task<int> UploadXmlAsync(string filePath, string title, string description = null)
  {
    var csrf = await GetCsrfTokenAsync("xml_documents/new");
    using (var form = new MultipartFormDataContent())
    {
      form.Add(new StringContent(csrf), "authenticity_token");
      form.Add(new StringContent(title), "xml_document[title]");
      if (!string.IsNullOrEmpty(description))
        form.Add(new StringContent(description), "xml_document[description]");

      var bytes = File.ReadAllBytes(filePath);
      var fileContent = new ByteArrayContent(bytes);
      fileContent.Headers.ContentType = new MediaTypeHeaderValue("text/xml");
      form.Add(fileContent, "xml_document[xml_file]", Path.GetFileName(filePath));

      var req = new HttpRequestMessage(HttpMethod.Post, "xml_documents") { Content = form };
      req.Headers.Add("X-CSRF-Token", csrf);
      var res = await _http.SendAsync(req);
      if (res.StatusCode != HttpStatusCode.Found) throw new Exception("Upload failed");
      var loc = res.Headers.Location == null ? "" : res.Headers.Location.ToString();
      var m = Regex.Match(loc, @"/xml_documents/(?<id>\d+)");
      if (!m.Success) throw new Exception("Unexpected Location");
      return int.Parse(m.Groups["id"].Value);
    }
  }
}

// エントリーポイント（async Mainが無い場合）
class Program
{
  static void Main(string[] args)
  {
    ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12;
    new Program().Run().GetAwaiter().GetResult();
  }

  private async Task Run()
  {
    using (var client = new RailsClient("http://127.0.0.1:3000"))
    {
      await client.SignupAsync("user@example.com", "Passw0rd!");
      // Login/Download/Logout も同様にフォーム/マルチパートを同期I/Oに置換して実装
    }
  }
}
```