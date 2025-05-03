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
    pub total_correct_guesses: u256,
    pub total_incorrect_guesses: u256,
    pub win_streak: u256,
    pub highest_win_streak: u256,
    pub last_game_timestamp: u64,
}


pub trait PlayerTrait {
    fn new(username: felt252, player: ContractAddress) -> Player;
    fn update_stats(
        ref self: Player,
        game_won: bool,
        correct_guesses: u256,
        incorrect_guesses: u256,
        timestamp: u64,
    );
}

impl PlayerImpl of PlayerTrait {
    fn new(username: felt252, player: ContractAddress) -> Player {
        Player {
            player,
            username,
            total_games_played: 0,
            total_games_completed: 0,
            total_games_won: 0,
            total_correct_guesses: 0,
            total_incorrect_guesses: 0,
            win_streak: 0,
            highest_win_streak: 0,
            last_game_timestamp: 0,
        }
    }

    fn update_stats(
        ref self: Player,
        game_won: bool,
        correct_guesses: u256,
        incorrect_guesses: u256,
        timestamp: u64,
    ) {
        self.total_games_played += 1;
        self.total_games_completed += 1;
        self.total_correct_guesses += correct_guesses;
        self.total_incorrect_guesses += incorrect_guesses;
        self.last_game_timestamp = timestamp;

        if game_won {
            self.total_games_won += 1;
            self.win_streak += 1;
            if self.win_streak > self.highest_win_streak {
                self.highest_win_streak = self.win_streak;
            }
        } else {
            self.win_streak = 0;
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

#[cfg(test)]
mod tests {
    use super::{PlayerImpl};
    use starknet::contract_address::contract_address_const;

    #[test]
    #[available_gas(999999)]
    fn test_player_creation() {
        let username = 'test_user';
        let player_address = contract_address_const::<0x1234>();
        let player = PlayerImpl::new(username, player_address);

        assert(player.username == username, 'Username should match');
        assert(player.player == player_address, 'Player address should match');
        assert(player.total_games_played == 0, 'Games played should be 0');
        assert(player.total_games_completed == 0, 'Games completed should be 0');
        assert(player.total_games_won == 0, 'Games won should be 0');
        assert(player.total_correct_guesses == 0, 'Correct guesses should be 0');
        assert(player.total_incorrect_guesses == 0, 'Incorrect guesses should be 0');
        assert(player.win_streak == 0, 'Win streak should be 0');
        assert(player.highest_win_streak == 0, 'Highest win streak should be 0');
        assert(player.last_game_timestamp == 0, 'Last game timestamp should be 0');
    }

    #[test]
    #[available_gas(999999)]
    fn test_update_stats_win() {
        let username = 'test_user';
        let player_address = contract_address_const::<0x1234>();
        let mut player = PlayerImpl::new(username, player_address);

        player.update_stats(true, 5, 2, 1000);

        assert(player.total_games_played == 1, 'Total games played should be 1');
        assert(player.total_games_completed == 1, 'Games completed should be 1');
        assert(player.total_games_won == 1, 'Games won should be 1');
        assert(player.total_correct_guesses == 5, 'Correct guesses should be 5');
        assert(player.total_incorrect_guesses == 2, 'Incorrect guesses should be 2');
        assert(player.win_streak == 1, 'Win streak should be 1');
        assert(player.highest_win_streak == 1, 'Highest win streak should be 1');
        assert(player.last_game_timestamp == 1000, 'Timestamp should be 1000');
    }

    #[test]
    #[available_gas(999999)]
    fn test_update_stats_loss() {
        let username = 'test_user';
        let player_address = contract_address_const::<0x1234>();
        let mut player = PlayerImpl::new(username, player_address);

        player.update_stats(false, 3, 4, 1000);

        assert(player.total_games_played == 1, 'Total games played should be 1');
        assert(player.total_games_completed == 1, 'Games cmpleted should be 1');
        assert(player.total_games_won == 0, 'Total games won should be 0');
        assert(player.total_correct_guesses == 3, 'Correct guesses should be 3');
        assert(player.total_incorrect_guesses == 4, 'Incorrect guesses should be 4');
        assert(player.win_streak == 0, 'Win streak should be 0');
        assert(player.highest_win_streak == 0, 'Highest win streak should be 0');
        assert(player.last_game_timestamp == 1000, 'Timestamp should be 1000');
    }

    #[test]
    #[available_gas(999999)]
    fn test_win_streak_updates() {
        let username = 'test_user';
        let player_address = contract_address_const::<0x1234>();
        let mut player = PlayerImpl::new(username, player_address);

        // Win 3 games in a row
        player.update_stats(true, 5, 2, 1000);
        player.update_stats(true, 4, 3, 2000);
        player.update_stats(true, 6, 1, 3000);

        assert(player.win_streak == 3, 'Win streak should be 3');
        assert(player.highest_win_streak == 3, 'Highest win streak should be 3');

        // Lose a game
        player.update_stats(false, 2, 5, 4000);

        assert(player.win_streak == 0, 'Win streak should reset to 0');
        assert(player.highest_win_streak == 3, 'Win streak should remain 3');

        // Win another game
        player.update_stats(true, 4, 3, 5000);

        assert(player.win_streak == 1, 'Win streak should be 1');
        assert(player.highest_win_streak == 3, 'Win streak should remain 3');
    }
}
