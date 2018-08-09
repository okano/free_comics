require 'test_helper'

class SeriesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @base_title = FreeComics::Application.config.site_title
  end

  test "should get index" do
    get series_index_url
    assert_response :success
    assert_select "title", "作品一覧 | #{@base_title}"
  end

end
