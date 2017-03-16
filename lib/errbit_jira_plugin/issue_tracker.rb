require 'jira-ruby'

module ErrbitJiraPlugin
  class IssueTracker < ErrbitPlugin::IssueTracker
    LABEL = 'jira'

    NOTE = 'Please configure Jira by entering the information below.'

    FIELDS = {
      :base_url => {
          :label => 'Jira URL without trailing slash',
          :placeholder => 'https://jira.example.org'
      },
      :context_path => {
          :optional => true,
          :label => 'Context Path (Just "/" if empty otherwise with leading slash)',
          :placeholder => "/jira"
      },
      :username => {
          :label => 'Username',
          :placeholder => 'johndoe'
      },
      :password => {
          :label => 'Password',
          :placeholder => 'p@assW0rd'
      },
      :project_id => {
          :label => 'Project Key',
          :placeholder => 'The project Key where the issue will be created'
      },
      :issue_priority => {
          :label => 'Priority',
          :placeholder => 'Normal'
      },
      :issue_type_id => {
          :optional => true,
          :label => 'Issue Type ID (found under issues in JIRA)',
          :placeholder => "10004"
      }
    }

    def self.label
      LABEL
    end

    def self.note
      NOTE
    end

    def self.fields
      FIELDS
    end

    def self.icons
      @icons ||= {
        create: [
          'image/png', ErrbitJiraPlugin.read_static_file('jira_create.png')
        ],
        goto: [
          'image/png', ErrbitJiraPlugin.read_static_file('jira_goto.png'),
        ],
        inactive: [
          'image/png', ErrbitJiraPlugin.read_static_file('jira_inactive.png'),
        ]
      }
    end

    def self.body_template
      @body_template ||= ERB.new(File.read(
        File.join(
          ErrbitJiraPlugin.root, 'views', 'jira_issues_body.txt.erb'
        )
      ))
    end

    def configured?
      options['project_id'].present?
    end

    def errors
      errors = []
      if self.class.fields.detect {|f| options[f[0]].blank? && !f[1][:optional]}
        errors << [:base, 'You must specify all non optional values!']
      end
      errors
    end

    def comments_allowed?
      false
    end

    def jira_options
      {
        :username => options['username'],
        :password => options['password'],
        :site => options['base_url'],
        :auth_type => :basic,
        :context_path => context_path
      }
    end

    def create_issue(title, body, user: {})
      begin
        client = JIRA::Client.new(jira_options)
        project = client.Project.find(options['project_id'])

        # Remove any newlines from the title
        title.delete!("\n")

        issue_fields =  {
                          "fields" => {
                            "summary" => title,
                            "description" => body,
                            "project"=> {"id"=> project.id},
                            "issuetype"=>{"id"=> issue_type_id},
                            "priority"=>{"name"=>options['issue_priority']}
                          }
                        }

        jira_issue = client.Issue.build

        jira_issue.save(issue_fields)

        if jira_issue.has_errors?
          raise "Jira validation errors: #{jira_issue.errors}"
        end

        jira_url(jira_issue.key)
      rescue JIRA::HTTPError
        raise ErrbitJiraPlugin::IssueError, "Could not create an issue with Jira.  Please check your credentials."
      end
    end

    def jira_url(issue_key)
      "#{options['base_url']}#{options['context_path']}browse/#{issue_key}"
    end

    def url
      options['base_url']
    end

    private

    def context_path
      if options['context_path'] == '/'
        ''
      else
        options['context_path']
      end
    end

    def issue_type_id
      if options['issue_type_id'].blank?
        '10004'
      else
        options['issue_type_id']
      end
    end

  end
end
