require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'your_secret' 

helpers do
  def new_deck
    card_number = ['A','2','3','4','5','6','7','8','9','10','J','Q','K']
    card_suit = ["\u2660","\u2665","\u2666","\u2663"]
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
      if card[0] == 'A'
        total +=11
        ace_count +=1
      elsif card[0] == 'J' || card[0] == 'Q' ||card[0] == 'K'
        total +=10
      else
        total +=card[0].to_i
      end
    end
    ace_count.times { total -=10 if total > 21 }
    return total
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
    @error = "Name is required"
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
  session[:player_money] = params[:player_money]
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
  end
  session[:player_bet] = params[:player_bet]
  redirect '/game'
end

get '/game' do
  reset
  first_draw(session[:player_cards], session[:dealer_cards], session[:decks])
  session[:player_total] = calculate_total(session[:player_cards])
  session[:dealer_total] = calculate_total(session[:dealer_cards])
  erb :game
end

get '/result' do
  erb :result
end



