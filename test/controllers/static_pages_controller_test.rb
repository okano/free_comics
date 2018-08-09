require 'test_helper'

class StaticPagesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @site_title = FreeComics::Application.config.site_title
  end

  test "should get about" do
    get static_pages_about_url
    assert_response :success
    assert_select "title", "About | #{@site_title}"
  end

end
