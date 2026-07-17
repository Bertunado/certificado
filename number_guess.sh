#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Gerar o número secreto entre 1 e 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

echo "Enter your username:"
read USERNAME

# Buscar informações do usuário
USER_INFO=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME'")

if [[ -z $USER_INFO ]]
then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
else
  echo "$USER_INFO" | while IFS="|" read GAMES_PLAYED BEST_GAME
  do
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  done
fi

echo "Guess the secret number between 1 and 1000:"
GUESS_COUNT=0

while true
do
  read GUESS
  ((GUESS_COUNT++))

  # Verificar se é um inteiro válido
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    # Diminui a contagem porque não foi um palpite numérico válido
    ((GUESS_COUNT--))
  elif [[ $GUESS -eq $SECRET_NUMBER ]]
  then
    break
  elif [[ $GUESS -gt $SECRET_NUMBER ]]
  then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi
done

echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"

# Atualizar estatísticas do usuário no banco
GAMES_PLAYED_CURRENT=$($PSQL "SELECT games_played FROM users WHERE username='$USERNAME'")
NEW_GAMES_PLAYED=$(( GAMES_PLAYED_CURRENT + 1 ))

BEST_GAME_CURRENT=$($PSQL "SELECT best_game FROM users WHERE username='$USERNAME'")

if [[ -z $BEST_GAME_CURRENT || $BEST_GAME_CURRENT -eq 9999 || $GUESS_COUNT -lt $BEST_GAME_CURRENT ]]
then
  UPDATE_STATS_RESULT=$($PSQL "UPDATE users SET games_played=$NEW_GAMES_PLAYED, best_game=$GUESS_COUNT WHERE username='$USERNAME'")
else
  UPDATE_STATS_RESULT=$($PSQL "UPDATE users SET games_played=$NEW_GAMES_PLAYED WHERE username='$USERNAME'")
fi