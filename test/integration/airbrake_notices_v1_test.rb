# Load the normal Rails helper
require File.expand_path File.dirname(__FILE__) + '/../test_helper'

class AirbrakeNoticesV1Test < Redmine::IntegrationTest
  fixtures :projects, :users, :trackers, :projects_trackers, :enumerations, :issue_statuses

  setup do
    Setting.mail_handler_api_key = 'secret'
    @project = Project.find 1
    @tracker = @project.trackers.first
    @notice = load_fixture "v1.yml"
    RedmineAirbrake::CustomFields.clear_cache
  end

  test "should update existing issue" do
    assert_difference "Issue.count", 1 do
      assert_difference "Journal.count", 1 do
        #request.env['RAW_POST_DATA'] = @notice
        post '/notices', params: @notice
      end
    end
    check_issue
    assert_response :success

    assert_no_difference "Issue.count", 1 do
      assert_difference "Journal.count", 1 do
        post '/notices', params: @notice
      end
    end
  end

  test "should render error for non existing project" do
    Project.find('ecookbook').update_column :identifier, 'wrong'
    assert_no_difference "Issue.count" do
      assert_no_difference "Journal.count" do
        post '/notices', params: @notice
      end
    end
    assert_response 400
  end

  test "should render error for non existing tracker" do
    Tracker.find_by_name('Bug').update_column :name, 'Error'
    assert_no_difference "Issue.count" do
      assert_no_difference "Journal.count" do
        post '/notices', params: @notice
      end
    end
    assert_response 400
  end

  test "should require valid api key" do
    with_settings mail_handler_api_key: 'wrong' do
      assert_no_difference "Issue.count" do
        assert_no_difference "Journal.count" do
          post '/notices', params: @notice
        end
      end
    end
    assert_response 403
  end

  def check_issue
    assert issue = Issue.where("subject like ?", "%RuntimeError%").last
    assert_equal(1, issue.journals.size)
    assert_equal(5, issue.priority_id)
    assert occurences_field = IssueCustomField.find_by_name('# Occurences')
    assert occurences_value = issue.custom_value_for(occurences_field)
    assert_equal('1', occurences_value.value)
  end

end

