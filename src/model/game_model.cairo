use starknet::{ContractAddress, get_block_timestamp, contract_address_const};
// Keeps track of the state of the game

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
#[dojo::model]
pub struct GameCounter {
    #[key]
    pub id: felt252,
    pub current_val: u256,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
#[dojo::model]
pub struct Game {
    #[key]
    pub id: u256, // Unique game/session identifier
    pub created_by: ContractAddress, // Address of session host
    pub status: GameStatus, // Pending, InProgress, Completed
    pub next_player: ContractAddress, // Address of player to submit statements or guess
    pub number_of_players: u8, // Max participants for this session
    pub created_at: u64, // Timestamp of session creation
    pub updated_at: u64,
}
pub trait GameTrait {
    // Create and return a new game
    fn new(
        id: u256,
        created_by: ContractAddress,
        status: GameStatus,
        next_player: ContractAddress,
        number_of_players: u8,
        created_at: u64,
        updated_at: u64,
    ) -> Game;
    fn restart(ref self: Game);
    fn terminate_game(ref self: Game);
}


// Represents the status of the game
// Can either be Ongoing or Ended
#[derive(Serde, Copy, Drop, Introspect, PartialEq, Debug)]
pub enum GameStatus {
    Pending, // Waiting for players to join (in multiplayer mode)
    Ongoing, // Game is ongoing
    Ended // Game has ended
}


impl GameImpl of GameTrait {
    fn new(
        id: u256,
        created_by: ContractAddress,
        status: GameStatus,
        next_player: ContractAddress,
        number_of_players: u8,
        created_at: u64,
        updated_at: u64,
    ) -> Game {
        let zero_address = contract_address_const::<0x0>();
        Game {
            id,
            created_by,
            status: GameStatus::Pending,
            next_player: zero_address.into(),
            number_of_players,
            created_at: get_block_timestamp(),
            updated_at: get_block_timestamp(),
        }
    }


    fn restart(ref self: Game) {}

    fn terminate_game(ref self: Game) {
        self.status = GameStatus::Ended;
    }
}

