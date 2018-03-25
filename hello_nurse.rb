require 'rubygems'
require 'bundler/setup'
require 'yaml'

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
@chain_options = @chain_options.merge(
  log: Logger.new(__FILE__.sub(/\.rb$/, '.log')),
  pool_size: 4
)

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

def voted_lately?(bot)
  @api.get_accounts([bot]) do |accounts, error|
    account = accounts.first
    last_vote_time = Time.parse(account.last_vote_time + 'Z')
    elapse = Time.now.utc - last_vote_time
    bot_voted_lately = elapse < @rules[:max_vote_elapse]
  
    ap "#{bot} may not be online." unless bot_voted_lately
  
    bot_voted_lately
  end
end

def transfer(op, comment)
  @bots.each do |bot|
    
    # We don't want to transfer if the bot isn't voting.  It might be offline.
    next unless voted_lately?(bot)
    
    voter = @voters[op.voter.to_sym]
    active_voters = comment.active_votes.map(&:voter)
    
    if active_voters.include? bot
      ap "#{bot} already voted."
      next
    end
    
    amount = voter[:amount]
    steem = Steem.new(account_name: op.voter, wif: voter[:active_key])
    options = {
      to: bot,
      amount: amount,
      memo: "https://steemit.com/#{comment.parent_permlink}/@#{comment.author}/#{comment.permlink}"
    }
    ap steem.transfer!(options)
  end
end

if @voters.nil? || @voters.empty?
  ap 'No voters defined.'
  exit
end

ap "Now watching #{@voters.keys.join(', ')} ..."

loop do
  @api = Radiator::Api.new(@chain_options)
  @stream = Radiator::Stream.new(@chain_options)
  
  mode = @config[:global][:mode].to_sym rescue :irreversible
  
  begin
    @stream.operations(:vote, nil, mode) do |op|
      @backoff ||= 0.001
      next unless may_transfer?(op)
      
      @api.get_content(op.author, op.permlink) do |comment, error|
        if !!error
          parser = Radiator::ErrorParser.new(error)
          raise StandardException, parser
        end
        
        transfer(op, comment)
      end
      
      @backoff = nil
    end
  rescue => e
    m = e.message
    
    ap "Pausing #{@backoff} :: Unable to stream on current node.  Error: #{e}"
    ap e.backtrace
      
    @api.shutdown
    @api = nil
    @stream.shutdown
    @stream = nil
    
    sleep @backoff
    @backoff = [@backoff * 2, MAX_BACKOFF].min
  end
end
