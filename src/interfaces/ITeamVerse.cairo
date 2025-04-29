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

    // 2 Truths and a Lie game functions
    fn submit_statement_set(
        ref self: T, game_id: u256, set_id: u8, statements: Array<felt252>, lie_index: u8,
    );
    fn get_player_statements(self: @T, player: ContractAddress, game_id: u256) -> PlayerStatements;
    fn get_statement(self: @T, player: ContractAddress, set_id: u8, statement_id: u8) -> Statement;
}
