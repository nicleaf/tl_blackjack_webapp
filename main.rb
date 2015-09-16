require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'your_secret' 

helpers do
  def new_deck
    card_number = ['a','2','3','4','5','6','7','8','9','10','j','q','k']
    card_suit = ["d","c","s","h"]
#    card_suit = ["\u2660","\u2665","\u2666","\u2663"]
    card_number.product(card_suit)
  end

  def first_draw(player,dealer,cards)
    2.times do |number|
      player << cards.pop
      dealer << cards.pop
    end
  end

  def reset
    session[:player_cards] =[]
    session[:dealer_cards] =[]
    session[:player_total] = 0
    session[:dealer_total] = 0
    session[:decks] = new_deck.shuffle
  end

  def calculate_total(cards_in_hand)
    total = 0
    ace_count = 0
    cards_in_hand.each do |card|
      if card[0] == 'a'
        total +=11
        ace_count +=1
      elsif card[0] == 'j' || card[0] == 'q' ||card[0] == 'k'
        total +=10
      else
        total +=card[0].to_i
      end
    end
    ace_count.times { total -=10 if total > 21 }
    return total
  end

  def hit_card(who,cards)
    who << cards.pop
  end

  def burst?(total)
    total > 21
  end

  def blackjack?(cards)
    if ((cards.sort[0][0] == '10') && (cards.sort[1][0] == 'a') || 
        ((cards.sort[0][0] == 'a') && ((cards.sort[1][0] == 'j') || 
        (cards.sort[1][0] == 'q')|| (cards.sort[1][0] == 'k'))))
      true
    else
      false
    end
  end

end

get '/' do
  redirect '/welcome'
end

get '/welcome' do
  erb :welcome, :layout => :layout2
end

get '/set_name' do
  erb :set_name, :layout => :layout2
end

post '/set_name' do
  if params[:player_name].empty?
    @error = "Name is required!"
    halt erb(:set_name, :layout => :layout2)
  end
  session[:player_name] = params[:player_name]
  redirect '/set_money'
end

get '/set_money' do
  erb :set_money, :layout => :layout2
end

post '/set_money' do
  if params[:player_money].empty?
    @error = "No empty value! Try again!"
    halt erb(:set_money, :layout => :layout2)
  elsif params[:player_money].to_i == 0
    @error = "No money??!!"
    halt erb(:set_money, :layout => :layout2)
  elsif params[:player_money].to_i < 0
    @error = "No negative value."
    halt erb(:set_money, :layout => :layout2)
  end
  session[:player_money] = params[:player_money].to_i
  redirect '/set_bet'
end

get '/set_bet' do
  erb :set_bet, :layout => :layout2
end

post '/set_bet' do
  if params[:player_bet].empty? || params[:player_bet].to_i == 0
    @error = "No empty value! Put some bet!"
    halt erb(:set_bet, :layout => :layout2)
  elsif params[:player_bet].to_i < 0
    @error = "No negative bet. Put some positive bet!"
    halt erb(:set_bet, :layout => :layout2)
  elsif params[:player_bet].to_i > session[:player_money].to_i
    @error = "Looks like you trying to bet more than what you have! Maximum bet is #{session[:player_money]}"
    halt erb(:set_bet, :layout => :layout2)
  end
  session[:player_bet] = params[:player_bet].to_i
  redirect '/game'
end

get '/game' do
  reset
  first_draw(session[:player_cards], session[:dealer_cards], session[:decks])
  session[:player_total] = calculate_total(session[:player_cards])
  session[:dealer_total] = calculate_total(session[:dealer_cards])
#  session[:player_cards] = [["A","G"],["K","G"]]
#  session[:dealer_cards] = [["A","G"],["K","G"]]
  if blackjack?(session[:player_cards]) && blackjack?(session[:dealer_cards])
    @tie = "Both BlackJack! It's a tie!"
    halt erb(:play_again)
  elsif blackjack?(session[:player_cards])
    @success = "#{session[:player_name]}, BlackJack! You win!"
    session[:player_money] = session[:player_money] + session[:player_bet]
    halt erb(:play_again)
#  elsif blackjack?(session[:dealer_cards])
#    @error = "Dealer BlackJack! You lost!"
#    halt erb(:play_again)
  end  
  erb :game
end

post '/game/hit' do
  hit_card(session[:player_cards],session[:decks])
  session[:player_total] = calculate_total(session[:player_cards])
  session[:dealer_total] = calculate_total(session[:dealer_cards])
  if burst?(session[:player_total])
    @error = "#{session[:player_name]}, you busted! Too bad!"
    session[:player_money] = session[:player_money] - session[:player_bet]
    halt erb(:play_again)
  end
  erb :game
end

post '/game/stay' do
  if blackjack?(session[:dealer_cards])
    @error = "Dealer BlackJack! You lost!"
    session[:player_money] = session[:player_money] - session[:player_bet]
    halt erb(:play_again)
  elsif session[:dealer_total] < 17
    begin
      hit_card(session[:dealer_cards],session[:decks])
      session[:dealer_total] = calculate_total(session[:dealer_cards])
    end until session[:dealer_total] >= 17 || burst?(session[:dealer_total])
  end
  
  if burst?(session[:dealer_total])
    @success = "#{session[:player_name]}, you win! As dealer busted!!!"
    session[:player_money] = session[:player_money] + session[:player_bet]
  elsif (session[:player_total]) > (session[:dealer_total])
    @success = "#{session[:player_name]}, you win!"
    session[:player_money] = session[:player_money] + session[:player_bet]
  elsif (session[:player_total]) == (session[:dealer_total])
    @tie = "It's tie! Better than losing, right!"
  else
    @error = "Dealer win! Better luck next time!"
    session[:player_money] = session[:player_money] - session[:player_bet]
  end
  erb(:play_again)
  
# erb :game_dealer
end

get '/result' do
  erb :result
end

get '/play_again' do
  erb :play_again, :layout => :layout2
end


