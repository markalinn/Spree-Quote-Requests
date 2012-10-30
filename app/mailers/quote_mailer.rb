class QuoteMailer < ActionMailer::Base
  helper "spree/base"

  def confirm_email(quote, resend=false)
    @quote_request = quote
    subject = (resend ? "[RESEND] " : "")
    subject += "#{Spree::Config[:site_name]} #{t('subject', :scope =>'quote_mailer.confirm_email')} ##{quote.number}"
    mail(:to => quote.email,
         :subject => subject)
  end
end
