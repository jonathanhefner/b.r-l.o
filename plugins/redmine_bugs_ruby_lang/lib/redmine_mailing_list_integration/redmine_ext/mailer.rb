module MailingListIntegrationMailer
  def issue_add(user, issue)
    if user
      super
    else
      mail = super(issue.author, issue)
      mailing_lists = issue.project.mail_routes_for_issue(issue)
      address_to_mailing_lists(mail, mailing_lists, issue: issue)
    end
  end

  def issue_edit(user, journal)
    if user
      super
    else
      issue = journal.issue
      mail = super(issue.author, journal)
      mailing_lists = issue.project.mail_routes_for_issue(issue)
      address_to_mailing_lists(mail, mailing_lists, issue: issue, journal: journal)
    end
  end

  def attachments_added(user, attachments)
    if user
      super
    else
      container = attachments.first.container
      mail = super(container.author, attachments)
      mailing_lists = container.project.mail_routes_for_attachments(attachments)
      address_to_mailing_lists(mail, mailing_lists)
    end
  end

  private

  def address_to_mailing_lists(mail, mailing_lists, record_attributes = nil)
    if record_attributes
      records = mailing_lists.map do |mailing_list|
        MailingListMessage.create!(mailing_list: mailing_list, **record_attributes)
      end
      mail.header["X-Redmine-MailingListIntegration-Message-Ids"] = records.map(&:id).join(",")
    end
    mail.to = mailing_lists.map(&:address)
    mail
  end
end

module MailingListIntegrationMailerSingleton
  def deliver_issue_add(issue)
    issue_add(nil, issue).deliver_later unless issue.originates_from_mail?
    super
  end

  def deliver_issue_edit(journal)
    issue_edit(nil, journal).deliver_later unless journal.originates_from_mail?
    super
  end

  def deliver_attachments_added(attachments)
    attachments_added(nil, attachments).deliver_later if attachments.first.container_type == "Issue"
    super
  end
end

Mailer.prepend MailingListIntegrationMailer
Mailer.singleton_class.prepend MailingListIntegrationMailerSingleton
