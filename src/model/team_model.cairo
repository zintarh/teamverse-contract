use starknet::{ContractAddress, contract_address_const};


use starknet::storage::{
    StoragePointerReadAccess, StoragePointerWriteAccess, Vec, VecTrait, MutableVecTrait,
};


#[derive(Serde, Drop, Introspect, PartialEq)]
#[dojo::model]
pub struct Team {
    #[key]
    pub team_id: u256,
    #[key]
    pub teamname: ContractAddress,
    creator: ContractAddress,
    created_at: u64,
    players: Array<ContractAddress>,
    total_games_played: u256,
    total_players: u256,
}


pub trait TeamTrait {
    fn new(username: felt252, player: ContractAddress) -> Team;
}


impl TraitImpl of TeamTrait {
    fn new(username: felt252, player: ContractAddress) -> Team {
        Team {
            team_id: 0,
            teamname: player,
            creator: player,
            created_at: 0,
            players: ArrayTrait::new(),
            total_games_played: 0,
            total_players: 0,
        }
    }
}
