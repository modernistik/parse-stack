
# See: https://github.com/modernistik/parse-stack#cloud-code-webhooks
Parse::Webhooks.route(:function, :helloWorld) do
  #  use the Parse::Payload instance methods in this block
  name = params['name'].to_s #function params

  # will return proper error response
  # error!("Missing argument 'name'.") unless name.present?

  name.present? ? "Hello #{name}!" : "Hello World!"
end
