use starknet::{ContractAddress, get_block_timestamp, contract_address_const};
// Keeps track of the state of the game

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
pub struct PlayerGameStats {
    pub player: ContractAddress,
    pub correct_guesses: u256,
    pub incorrect_guesses: u256,
    pub score: u256,
}

#[derive(Serde, Copy, Drop, Introspect, PartialEq)]
#[dojo::model]
pub struct GameCounter {
    #[key]
    pub id: felt252,
    pub current_val: u256,
}

#[derive(Serde, Drop, Introspect, PartialEq)]
#[dojo::model]
pub struct Game {
    #[key]
    pub id: u256, // Unique game/session identifier
    pub created_by: ContractAddress, // Address of session host
    pub status: GameStatus, // Pending, InProgress, Completed
    pub next_player: ContractAddress, // Address of player to submit statements or guess
    pub number_of_players: u8, // Max participants for this session
    pub current_round: u8, // Current round number
    pub max_rounds: u8, // Maximum number of rounds
    pub winner: ContractAddress, // Address of the winner
    pub player_stats: Array<PlayerGameStats>, // Stats for each player in the game
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
        current_round: u8,
        max_rounds: u8,
        winner: ContractAddress,
        player_stats: Array<PlayerGameStats>,
        created_at: u64,
        updated_at: u64,
    ) -> Game;
    fn update_player_stats(
        ref self: Game, player: ContractAddress, correct_guesses: u256, incorrect_guesses: u256,
    );
    fn set_winner(ref self: Game, winner: ContractAddress);
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
        current_round: u8,
        max_rounds: u8,
        winner: ContractAddress,
        player_stats: Array<PlayerGameStats>,
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
            current_round,
            max_rounds,
            winner,
            player_stats,
            created_at: get_block_timestamp(),
            updated_at: get_block_timestamp(),
        }
    }

    fn update_player_stats(
        ref self: Game, player: ContractAddress, correct_guesses: u256, incorrect_guesses: u256,
    ) {
        let mut stats = self.player_stats;
        let mut found = false;
        let mut i = 0;

        let mut new_stats = ArrayTrait::new();

        loop {
            if i >= stats.len() {
                break;
            }

            let mut player_stat = *stats[i];

            if player_stat.player == player {
                player_stat.correct_guesses += correct_guesses;
                player_stat.incorrect_guesses += incorrect_guesses;
                player_stat.score = player_stat.correct_guesses * 2 - player_stat.incorrect_guesses;
                new_stats.append(player_stat);
                i += 1;
                found = true;
                continue;
            }

            new_stats.append(player_stat);

            i += 1;
        };

        if !found {
            let new_player_stat = PlayerGameStats {
                player,
                correct_guesses,
                incorrect_guesses,
                score: correct_guesses * 2 - incorrect_guesses,
            };
            new_stats.append(new_player_stat);
        }

        self.player_stats = new_stats;
    }

    fn set_winner(ref self: Game, winner: ContractAddress) {
        self.winner = winner;
    }

    fn restart(ref self: Game) {}

    fn terminate_game(ref self: Game) {
        self.status = GameStatus::Ended;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    #[available_gas(999999)]
    fn test_game_creation() {
        let game_id = 1;
        let creator = contract_address_const::<0x1234>();
        let player1 = contract_address_const::<0x5678>();
        let player2 = contract_address_const::<0x9abc>();

        let mut player_stats: Array<PlayerGameStats> = ArrayTrait::new();
        player_stats
            .append(
                PlayerGameStats {
                    player: player1, correct_guesses: 0, incorrect_guesses: 0, score: 0,
                },
            );
        player_stats
            .append(
                PlayerGameStats {
                    player: player2, correct_guesses: 0, incorrect_guesses: 0, score: 0,
                },
            );

        let game = GameImpl::new(
            game_id,
            creator,
            GameStatus::Pending,
            player1,
            2,
            1,
            5,
            contract_address_const::<0x0>(),
            player_stats,
            get_block_timestamp(),
            get_block_timestamp(),
        );

        let zero_address = contract_address_const::<0x0>();

        assert(game.id == game_id, 'Game ID should match');
        assert(game.created_by == creator, 'Creator address should match');
        assert(game.status == GameStatus::Pending, 'Status should be Pending');
        assert(game.next_player == zero_address, 'Next player zero');
        assert(game.number_of_players == 2, 'Number of players should be 2');
        assert(game.current_round == 1, 'Current round should be 1');
        assert(game.max_rounds == 5, 'Max rounds should be 5');
        assert(game.winner == zero_address.into(), 'Winner should be zero address');
        assert(game.player_stats.len() == 2, 'Player stats should be 2');
        assert(game.created_at == get_block_timestamp(), 'Timestamp should be set');
        assert(game.updated_at == get_block_timestamp(), 'Timestamp should be set');
    }

    #[test]
    #[available_gas(999999)]
    fn test_game_status_transitions() {
        let game_id = 1;
        let creator = contract_address_const::<0x1234>();
        let player1 = contract_address_const::<0x5678>();

        let mut player_stats: Array<PlayerGameStats> = ArrayTrait::new();
        player_stats
            .append(
                PlayerGameStats {
                    player: player1, correct_guesses: 0, incorrect_guesses: 0, score: 0,
                },
            );

        let mut game = GameImpl::new(
            game_id,
            creator,
            GameStatus::Pending,
            player1,
            1,
            1,
            5,
            contract_address_const::<0x0>(),
            player_stats,
            get_block_timestamp(),
            get_block_timestamp(),
        );

        // Test game termination
        game.terminate_game();
        assert(game.status == GameStatus::Ended, 'Status should be Ended');
    }

    #[test]
    #[available_gas(999999)]
    fn test_player_game_stats() {
        let game_id = 1;
        let creator = contract_address_const::<0x1234>();
        let player1 = contract_address_const::<0x5678>();

        let mut player_stats: Array<PlayerGameStats> = ArrayTrait::new();
        player_stats
            .append(
                PlayerGameStats {
                    player: player1, correct_guesses: 0, incorrect_guesses: 0, score: 0,
                },
            );

        let game = GameImpl::new(
            game_id,
            creator,
            GameStatus::Pending,
            player1,
            1,
            1,
            5,
            contract_address_const::<0x0>(),
            player_stats,
            get_block_timestamp(),
            get_block_timestamp(),
        );

        let player1_stats = game.player_stats.at(0);
        assert(player1_stats.player == @player1, 'Player address should match');
        assert(player1_stats.correct_guesses == @0_u256, 'Correct guesses should be 0');
        assert(player1_stats.incorrect_guesses == @0_u256, 'Incorrect guesses should be 0');
        assert(player1_stats.score == @0_u256, 'Initial score should be 0');
    }

    #[test]
    fn test_update_existing_player_stats() {
        let game_id = 1;
        let creator = contract_address_const::<0x1234>();
        let player1 = contract_address_const::<0x5678>();

        let mut player_stats: Array<PlayerGameStats> = ArrayTrait::new();
        player_stats
            .append(
                PlayerGameStats {
                    player: player1, correct_guesses: 0, incorrect_guesses: 0, score: 0,
                },
            );

        let mut game = GameImpl::new(
            game_id,
            creator,
            GameStatus::Pending,
            player1,
            1,
            1,
            5,
            contract_address_const::<0x0>(),
            player_stats,
            get_block_timestamp(),
            get_block_timestamp(),
        );

        // Update existing player stats
        game.update_player_stats(player1, 3, 1);

        let updated_stats = game.player_stats.at(0);
        assert(updated_stats.player == @player1, 'Player address should match');
        println!("updated_stats.correct_guesses: {}", updated_stats.correct_guesses);
        assert(updated_stats.correct_guesses == @3_u256, 'Correct guesses should be 3');
        assert(updated_stats.incorrect_guesses == @1_u256, 'Incorrect guesses should be 1');
        assert(updated_stats.score == @5_u256, 'Score should be 5 (3*2 - 1)');

        // Update again to test accumulation
        game.update_player_stats(player1, 2, 1);

        let final_stats = game.player_stats.at(0);
        assert(final_stats.correct_guesses == @5_u256, 'Correct guesses should be 5');
        assert(final_stats.incorrect_guesses == @2_u256, 'Incorrect guesses should be 2');
        assert(final_stats.score == @8_u256, 'Score should be 8 (5*2 - 2)');
    }

    #[test]
    #[available_gas(999999)]
    fn test_add_new_player_stats() {
        let game_id = 1;
        let creator = contract_address_const::<0x1234>();
        let player1 = contract_address_const::<0x5678>();
        let player2 = contract_address_const::<0x9abc>();

        let mut player_stats: Array<PlayerGameStats> = ArrayTrait::new();
        player_stats
            .append(
                PlayerGameStats {
                    player: player1, correct_guesses: 0, incorrect_guesses: 0, score: 0,
                },
            );

        let mut game = GameImpl::new(
            game_id,
            creator,
            GameStatus::Pending,
            player1,
            2,
            1,
            5,
            contract_address_const::<0x0>(),
            player_stats,
            get_block_timestamp(),
            get_block_timestamp(),
        );

        // Add stats for a new player
        game.update_player_stats(player2, 4, 2);

        assert(game.player_stats.len() == 2, '2 players expected');

        // Verify new player stats
        let new_player_stats = game.player_stats.at(1);
        assert(new_player_stats.player == @player2, 'Address should match');
        assert(new_player_stats.correct_guesses == @4_u256, 'Correct guesses should be 4');
        assert(new_player_stats.incorrect_guesses == @2_u256, 'Incorrect guesses should be 2');
        assert(new_player_stats.score == @6_u256, 'Score should be 6');

        // Verify original player stats unchanged
        let original_stats = game.player_stats.at(0);
        assert(original_stats.player == @player1, 'Player address should match');
        assert(original_stats.correct_guesses == @0_u256, 'Correct guesses should be 0');
        assert(original_stats.incorrect_guesses == @0_u256, 'Incorrect guesses should be 0');
        assert(original_stats.score == @0_u256, 'Score should be 0');
    }
}
