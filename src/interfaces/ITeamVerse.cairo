use starknet::{ContractAddress};
use dojo_starter::model::game_model::{Game};
use dojo_starter::model::player_model::{Player};
#[starknet::interface]
pub trait ITeamVerse<T> {
    fn register_new_player(ref self: T, username: felt252);
    fn create_new_game(ref self: T, number_of_players: u8) -> u256;
    fn get_username_from_address(self: @T, address: ContractAddress) -> felt252;
    fn create_new_game_id(ref self: T) -> u256;
    fn retrieve_game(ref self: T, game_id: u256) -> Game;
    fn retrieve_player(ref self: T, addr: ContractAddress) -> Player;
    fn join_game(ref self: T, game_id: u256);
    fn update_game_stats(
        ref self: T,
        game_id: u256,
        player: ContractAddress,
        correct_guesses: u256,
        incorrect_guesses: u256,
    );
    fn end_game(ref self: T, game_id: u256, winner: ContractAddress);
}
