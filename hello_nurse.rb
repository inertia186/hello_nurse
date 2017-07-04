require 'rubygems'
require 'bundler/setup'
require 'yaml'
require 'pry'

Bundler.require

# If there are problems, this is the most time we'll wait (in seconds).
MAX_BACKOFF = 12.8

@config_path = __FILE__.sub(/\.rb$/, '.yml')

unless File.exist? @config_path
  ap "Unable to find: #{@config_path}"
  exit
end

@config = YAML.load_file(@config_path)
@rules = @config[:voting_rules]
@trigger_vote_weight = (((@rules[:trigger_vote_weight] || '0.0 %').to_f) * 100).to_i
@voters = @config[:voters]
@bots = @config[:bots].split(' ')
@chain_options = @config[:chain_options]
@chain_options = @chain_options.merge(log: Logger.new(__FILE__.sub(/\.rb$/, '.log')))

def may_transfer?(op)
  return false unless @voters.keys.include? op.voter.to_sym
  
  if @trigger_vote_weight == op.weight
    ap "#{op.voter} voted, ready to transfer."
    true
  else
    ap "#{op.voter} voted, ignoring (weight: #{(op.weight / 100.0)} %)."
    false
  end
end

def transfer(op, comment)
  @bots.each do |bot|
    voter = @voters[op.voter.to_sym]
    active_voters = comment.active_votes.map(&:voter)
    
    if active_voters.include? bot
      ap "#{bot} already voted."
      next
    end
    
    amount = voter[:amount]
    transfer = {
      type: :transfer,
      from: op.voter,
      to: bot,
      amount: amount,
      memo: "@#{comment.author}/#{comment.permlink}"
    }
    
    wif = voter[:active_key]
    tx = Radiator::Transaction.new(@chain_options.dup.merge(wif: wif))
    tx.operations << transfer
    ap tx.process(true)
  end
end

if @voters.nil? || @voters.empty?
  ap 'No voters defined.'
  exit
end

ap "Now watching #{@voters.keys.join(', ')} ..."

loop do
  @api = Radiator::Api.new(@chain_options.dup)
  @stream = Radiator::Stream.new(@chain_options.dup)
  
  mode = @config[:global][:mode].to_sym rescue :irreversible
  
  begin
    @stream.operations(:vote, nil, mode) do |op|
      @backoff ||= 0.001
      next unless may_transfer?(op)
      response = @api.get_content(op.author, op.permlink)
      comment = response.result
      
      transfer(op, comment)
      
      @backoff = nil
    end
  rescue => e
    m = e.message
    
    if m =~ /undefined method `transactions' for nil:NilClass/ && mode == :head
      # Block hasn't reached the node yet.  Just retry with a small delay
      # without reporting an error.
      
      sleep 0.2
    else
      ap "Pausing #{@backoff} :: Unable to stream on current node.  Error: #{e}"
      ap e.backtrace
      
      sleep @backoff
      @backoff = [@backoff * 2, MAX_BACKOFF].min
    end
  end
end