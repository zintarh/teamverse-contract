use starknet::{ContractAddress, contract_address_const};


#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
#[dojo::model]
pub struct Player {
    #[key]
    pub player: ContractAddress,
    pub username: felt252,
    pub total_games_played: u256,
    pub total_games_completed: u256,
    pub total_games_won: u256,
}


pub trait PlayerTrait {
    fn new(username: felt252, player: ContractAddress) -> Player;
}

impl PlayerImpl of PlayerTrait {
    fn new(username: felt252, player: ContractAddress) -> Player {
        Player {
            player, username, total_games_played: 0, total_games_completed: 0, total_games_won: 0,
        }
    }
}


#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct UsernameToAddress {
    #[key]
    pub username: felt252,
    pub address: ContractAddress,
}

#[derive(Drop, Copy, Serde)]
#[dojo::model]
pub struct AddressToUsername {
    #[key]
    pub address: ContractAddress,
    pub username: felt252,
}


// Statement struct - represents a single statement in the 2 truths and a lie game
#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
#[dojo::model]
pub struct Statement {
    #[key]
    pub player: ContractAddress,
    #[key]
    pub set_id: u8, // Set ID (1, 2, or 3)
    #[key]
    pub statement_id: u8, // Statement ID (1, 2, or 3) within the set
    pub content: felt252, // Content of the statement
    pub is_truth: bool // True if statement is a truth, False if it's a lie
}

// Player Statements tracker - tracks how many statement sets a player has submitted
#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
#[dojo::model]
pub struct PlayerStatements {
    #[key]
    pub player: ContractAddress,
    #[key]
    pub game_id: u256, // Game ID to associate statements with
    pub sets_submitted: u8, // Number of statement sets submitted (max 3)
    pub has_submitted: bool // Whether the player has submitted their statements
}

pub trait StatementTrait {
    fn new(
        player: ContractAddress, set_id: u8, statement_id: u8, content: felt252, is_truth: bool,
    ) -> Statement;
}

impl StatementImpl of StatementTrait {
    fn new(
        player: ContractAddress, set_id: u8, statement_id: u8, content: felt252, is_truth: bool,
    ) -> Statement {
        Statement { player, set_id, statement_id, content, is_truth }
    }
}
