namespace :advisor do
  desc "Make one minimal Farming Advisor call and report whether the LLM answered. Failures are logged by LlmClient."
  task check: :environment do
    response = LlmClient.ask("Reply with the single word OK.")

    if LlmClient.fallback?(response)
      puts "FAILED: the advisor returned its fallback message. Look for an 'LlmClient' line in the logs (class and message explain why)."
      exit 1
    else
      puts "OK: #{response.to_s.squish.truncate(120)}"
    end
  end
end
