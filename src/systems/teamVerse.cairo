use dojo_starter::interfaces::ITeamVerse::ITeamVerse;
// define the interface

// dojo decorator
#[dojo::contract]
pub mod teamVerse {
    use dojo::event::EventStorage;
    // use dojo_starter::models::{Vec2, Moves};

    use dojo::model::{ModelStorage};
    use dojo_starter::model::game_model::{Game, GameCounter, GameStatus, GameTrait};
    use dojo_starter::model::player_model::{
        AddressToUsername, Player, PlayerStatements, PlayerTrait, Statement, StatementTrait,
        UsernameToAddress,
    };
    use starknet::{
        ContractAddress, contract_address_const, get_block_timestamp, get_caller_address,
    };
    use super::ITeamVerse;

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
    pub struct StatementSetSubmitted {
        #[key]
        pub player: ContractAddress,
        #[key]
        pub game_id: u256,
        pub set_id: u8,
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

            // Create a new game
            let mut new_game: Game = GameTrait::new(
                id: game_id,
                created_by: caller,
                status: GameStatus::Pending,
                next_player: caller,
                number_of_players: number_of_players,
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

        // 2 Truths and a Lie implementations
        fn submit_statement_set(
            ref self: ContractState,
            game_id: u256,
            set_id: u8,
            statements: Array<felt252>,
            lie_index: u8,
        ) {
            let mut world = self.world_default();
            let caller = get_caller_address();

            // Validate inputs
            assert(set_id > 0 && set_id <= 3, 'SET_ID MUST BE 1-3');
            assert(statements.len() == 3, 'MUST PROVIDE 3 STATEMENTS');
            assert(lie_index >= 1 && lie_index <= 3, 'LIE_INDEX MUST BE 1-3');

            // Ensure the game exists and is ongoing
            let game: Game = world.read_model(game_id);
            assert(game.id == game_id, 'GAME DOES NOT EXIST');
            assert(game.status != GameStatus::Ended, 'GAME HAS ENDED');

            // Check if player has already submitted max sets
            let mut player_statements: PlayerStatements = world.read_model((caller, game_id));
            assert(player_statements.sets_submitted < 3, 'MAX SETS SUBMITTED');

            // Create statements (2 truths and 1 lie)
            let mut i: u8 = 1;
            let mut truth_count: u8 = 0;
            let mut lie_count: u8 = 0;

            loop {
                if i > 3 {
                    break;
                }

                let statement_content = *statements.at(i.into() - 1);
                assert(statement_content != 0, 'STATEMENT CANNOT BE EMPTY');

                let is_truth = i != lie_index;

                if is_truth {
                    truth_count += 1;
                } else {
                    lie_count += 1;
                }

                let statement = StatementTrait::new(caller, set_id, i, statement_content, is_truth);

                world.write_model(@statement);

                i += 1;
            }

            // Validate we have exactly 2 truths and 1 lie
            assert(truth_count == 2, 'MUST HAVE EXACTLY 2 TRUTHS');
            assert(lie_count == 1, 'MUST HAVE EXACTLY 1 LIE');

            // Update player's submitted sets count
            player_statements.sets_submitted += 1;
            player_statements.has_submitted = true;
            world.write_model(@player_statements);

            // Emit event for statement submission
            let timestamp = get_block_timestamp();
            world.emit_event(@StatementSetSubmitted { player: caller, game_id, set_id, timestamp });
        }

        fn get_player_statements(
            self: @ContractState, player: ContractAddress, game_id: u256,
        ) -> PlayerStatements {
            let world = self.world_default();
            let player_statements: PlayerStatements = world.read_model((player, game_id));
            player_statements
        }

        fn get_statement(
            self: @ContractState, player: ContractAddress, set_id: u8, statement_id: u8,
        ) -> Statement {
            let world = self.world_default();
            let statement: Statement = world.read_model((player, set_id, statement_id));
            statement
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

