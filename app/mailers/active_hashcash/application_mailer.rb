module ActiveHashcash
  class ApplicationMailer < ActionMailer::Base # :nodoc:
    default from: "from@example.com"
    layout "mailer"
  end
end
