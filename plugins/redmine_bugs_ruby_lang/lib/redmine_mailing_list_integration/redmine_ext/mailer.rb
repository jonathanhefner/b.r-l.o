module MailingListIntegration
  def deliver_issue_add(issue)
    deliver_issue_add_to_mailing_lists(issue) unless issue.originates_from_mail?
    super
  end

  def deliver_issue_edit(journal)
    deliver_issue_edit_to_mailing_lists(journal) unless journal.originates_from_mail?
    super
  end

  def deliver_attachments_added(attachments)
    deliver_attachments_added_to_mailing_lists(attachments) if attachments.first.container_type == "Issue"
    super
  end

  private

  def deliver_issue_add_to_mailing_lists(issue)
    mail = issue_add(issue.author, issue)
    mailing_lists = issue.project.mail_routes_for_issue(issue)
    deliver_to_mailing_lists(mail, mailing_lists, issue: issue)
  end

  def deliver_issue_edit_to_mailing_lists(journal)
    issue = journal.issue
    mail = issue_edit(issue.author, journal)
    mailing_lists = issue.project.mail_routes_for_issue(issue)
    deliver_to_mailing_lists(mail, mailing_lists, issue: issue, journal: journal)
  end

  def deliver_attachments_added_to_mailing_lists(attachments)
    container = attachments.first.container
    mail = attachments_added(container.author, attachments)
    mailing_lists = container.project.mail_routes_for_attachments(attachments)
    deliver_to_mailing_lists(mail, mailing_lists)
  end

  def deliver_to_mailing_lists(mail, mailing_lists, record_attributes = nil)
    if record_attributes
      records = mailing_lists.map do |mailing_list|
        MailingListMessage.create!(mailing_list: mailing_list, **record_attributes)
      end
      mail.header["X-Redmine-MailingListIntegration-Message-Ids"] = records.map(&:id).join(",")
    end
    mail.to = mailing_lists.map(&:address)
    mail.deliver_later
  end
end

Mailer.singleton_class.prepend MailingListIntegration
