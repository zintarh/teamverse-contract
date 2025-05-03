use dojo_starter::interfaces::ITeamVerse::ITeamVerse;
// define the interface

use dojo_starter::model::team_model::{Team, TeamTrait};
// dojo decorator
#[dojo::contract]
pub mod teamVerse {
    use super::{ITeamVerse};
    use dojo_starter::model::player_model::{
        Player, UsernameToAddress, AddressToUsername, PlayerTrait,
    };
    use dojo_starter::model::game_model::{GameCounter, Game, GameTrait, GameStatus};
    use starknet::{
        ContractAddress, get_caller_address, contract_address_const, get_block_timestamp,
    };
    // use dojo_starter::models::{Vec2, Moves};

    use dojo::model::{ModelStorage};
    use dojo::event::EventStorage;

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct PlayerCreated {
        #[key]
        pub player: ContractAddress,
        pub username: felt252,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct GameCreated {
        #[key]
        pub game_id: u256,
        pub timestamp: u64,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct PlayerStatsUpdated {
        #[key]
        pub player: ContractAddress,
        pub game_id: u256,
        pub correct_guesses: u256,
        pub incorrect_guesses: u256,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct GameEnded {
        #[key]
        pub game_id: u256,
        pub winner: ContractAddress,
        pub timestamp: u64,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct PlayerJoined {
        #[key]
        pub game_id: u256,
        pub player: ContractAddress,
        pub timestamp: u64,
    }

    #[abi(embed_v0)]
    impl TeamVerseImpl of ITeamVerse<ContractState> {
        fn get_username_from_address(self: @ContractState, address: ContractAddress) -> felt252 {
            let mut world = self.world_default();

            let address_map: AddressToUsername = world.read_model(address);

            address_map.username
        }
        fn register_new_player(ref self: ContractState, username: felt252) {
            let mut world = self.world_default();

            let player: ContractAddress = get_caller_address();

            let zero_address: ContractAddress = contract_address_const::<0x0>();

            // Validate username
            assert(username != 0, 'USERNAME CANNOT BE ZERO');

            // Check if the player already exists (ensure username is unique)
            let existing_player: UsernameToAddress = world.read_model(username);
            assert(existing_player.address == zero_address, 'USERNAME ALREADY TAKEN');

            // Ensure player cannot update username by calling this function
            let existing_username = self.get_username_from_address(player);

            assert(existing_username == 0, 'USERNAME ALREADY CREATED');

            let new_player: Player = PlayerTrait::new(username, player);
            let username_to_address: UsernameToAddress = UsernameToAddress {
                username, address: player,
            };
            let address_to_username: AddressToUsername = AddressToUsername {
                address: player, username,
            };

            world.write_model(@new_player);
            world.write_model(@username_to_address);
            world.write_model(@address_to_username);
            world.emit_event(@PlayerCreated { player, username });
        }

        fn create_new_game_id(ref self: ContractState) -> u256 {
            let mut world = self.world_default();
            let mut game_counter: GameCounter = world.read_model('v0');
            let new_val = game_counter.current_val + 1;
            game_counter.current_val = new_val;
            world.write_model(@game_counter);
            new_val
        }

        fn create_new_game(ref self: ContractState, number_of_players: u8) -> u256 {
            assert(number_of_players > 1, 'You cannot Play alone');
            let mut world = self.world_default();

            // Caller must be registered
            let caller = get_caller_address();
            let caller_name = self.get_username_from_address(caller);
            assert(caller_name != 0, 'PLAYER NOT REGISTERED');

            // Generate session ID and timestamp

            let game_id = self.create_new_game_id();
            let timestamp = get_block_timestamp();

            let zero_address = contract_address_const::<0x0>();

            // Create a new game
            let mut new_game: Game = GameTrait::new(
                id: game_id,
                created_by: caller,
                status: GameStatus::Pending,
                next_player: caller,
                number_of_players: number_of_players,
                current_round: 0,
                max_rounds: 10,
                winner: zero_address,
                player_stats: ArrayTrait::new(),
                created_at: timestamp,
                updated_at: timestamp,
            );

            world.write_model(@new_game);

            world.emit_event(@GameCreated { game_id, timestamp });

            game_id
        }

        fn retrieve_game(ref self: ContractState, game_id: u256) -> Game {
            // Get default world
            let mut world = self.world_default();
            //get the game state
            let game: Game = world.read_model(game_id);
            game
        }
        fn retrieve_player(ref self: ContractState, addr: ContractAddress) -> Player {
            // Get default world
            let mut world = self.world_default();
            let player: Player = world.read_model(addr);

            player
        }

        fn join_game(ref self: ContractState, game_id: u256) {
            // Get default world
            let mut world = self.world_default();

            // Caller must be registered
            let caller = get_caller_address();
            let caller_name = self.get_username_from_address(caller);
            assert(caller_name != 0, 'PLAYER NOT REGISTERED');

            let game: Game = world.read_model(game_id);

            // Check if the game is in a valid state
            assert(game.status == GameStatus::Pending, 'GAME NOT IN PENDING STATE');

            world
                .emit_event(
                    @PlayerJoined { game_id, player: caller, timestamp: get_block_timestamp() },
                );
        }

        fn update_game_stats(
            ref self: ContractState,
            game_id: u256,
            player: ContractAddress,
            correct_guesses: u256,
            incorrect_guesses: u256,
        ) {
            let mut world = self.world_default();
            let mut game: Game = world.read_model(game_id);

            // Only allow updates for active games
            assert(game.status == GameStatus::Ongoing, 'GAME NOT ACTIVE');

            // Update game stats
            game.update_player_stats(player, correct_guesses, incorrect_guesses);
            world.write_model(@game);

            // Emit event
            world
                .emit_event(
                    @PlayerStatsUpdated { player, game_id, correct_guesses, incorrect_guesses },
                );
        }

        fn end_game(ref self: ContractState, game_id: u256, winner: ContractAddress) {
            let mut world = self.world_default();
            let mut game: Game = world.read_model(game_id);

            // Only allow ending active games
            assert(game.status == GameStatus::Ongoing, 'GAME NOT ACTIVE');

            // Update game status and winner
            game.set_winner(winner);
            game.terminate_game();
            world.write_model(@game);

            // Update player stats
            let mut player: Player = world.read_model(winner);
            let player_stats = game.player_stats;
            let mut i = 0;
            loop {
                if i >= player_stats.len() {
                    break;
                }

                let player_stat = *player_stats[i];

                if player_stat.player == winner {
                    player
                        .update_stats(
                            true,
                            player_stat.correct_guesses,
                            player_stat.incorrect_guesses,
                            get_block_timestamp(),
                        );
                    break;
                }

                i += 1;
            };

            world.write_model(@player);

            // Emit event
            world.emit_event(@GameEnded { game_id, winner, timestamp: get_block_timestamp() });
        }

        fn create_team(ref self: ContractState, team_name: felt252) -> bool {
            let mut world = self.world_default();

            let creator: ContractAddress = get_caller_address();

            let zero_address: ContractAddress = contract_address_const::<0x0>();

            // Validate team name

            assert(team_name != 0, 'TEAM NAME CANNOT BE ZERO');

            // world.write_model(@new_team);

            true
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// Use the default namespace "dojo_starter". This function is handy since the ByteArray
        /// can't be const.
        fn world_default(self: @ContractState) -> dojo::world::WorldStorage {
            self.world(@"dojo_starter")
        }
    }
}

