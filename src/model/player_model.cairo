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
