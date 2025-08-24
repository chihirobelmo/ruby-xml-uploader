require "test_helper"

class AuthFlowTest < ActionDispatch::IntegrationTest
  test "sign up, login, logout flow" do
    # Sign up
    get "/signup"
    assert_response :success
    assert_select "form[action='/signup']"

    assert_difference "User.count", 1 do
      post "/signup", params: {
        user: {
          username: "flow-user",
          email: "flow@example.com",
          password: "password",
          password_confirmation: "password"
        }
      }
    end
    follow_redirect!
    assert_response :success

  # Logout current session (integration tests can issue DELETE directly)
  delete "/logout"
    follow_redirect!
    assert_response :success

    # Login with remember me
    get "/login"
    assert_response :success
    post "/login", params: {
      email: "flow@example.com",
      password: "password",
      remember_me: "1"
    }
    follow_redirect!
    assert_response :success
  end
end
