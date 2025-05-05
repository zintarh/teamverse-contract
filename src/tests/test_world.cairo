#[cfg(test)]
mod tests {
    use dojo_cairo_test::WorldStorageTestTrait;
    use dojo::model::{ModelStorage, ModelStorageTest};
    use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{
        spawn_test_world, NamespaceDef, TestResource, ContractDefTrait, ContractDef,
    };

    use dojo_starter::systems::teamVerse::{teamVerse};
    use dojo_starter::interfaces::ITeamVerse::{ITeamVerseDispatcher, ITeamVerseDispatcherTrait};
    use dojo_starter::model::game_model::{
        Game, m_Game, GameStatus, GameCounter, m_GameCounter, RoundQuestions, m_RoundQuestions,
    };

    use dojo_starter::model::player_model::{
        Player, m_Player, UsernameToAddress, m_UsernameToAddress, AddressToUsername,
        m_AddressToUsername,
    };


    use starknet::{testing, get_caller_address, contract_address_const};


    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "dojo_starter",
            resources: [
                TestResource::Model(m_Player::TEST_CLASS_HASH),
                TestResource::Model(m_UsernameToAddress::TEST_CLASS_HASH),
                TestResource::Model(m_AddressToUsername::TEST_CLASS_HASH),
                TestResource::Model(m_Game::TEST_CLASS_HASH),
                TestResource::Model(m_GameCounter::TEST_CLASS_HASH),
                TestResource::Model(m_RoundQuestions::TEST_CLASS_HASH),
                TestResource::Event(teamVerse::e_PlayerCreated::TEST_CLASS_HASH),
                TestResource::Event(teamVerse::e_GameCreated::TEST_CLASS_HASH),
                TestResource::Event(teamVerse::e_PlayerJoined::TEST_CLASS_HASH),
                TestResource::Event(teamVerse::e_QuestionsSubmitted::TEST_CLASS_HASH),
                TestResource::Contract(teamVerse::TEST_CLASS_HASH),
            ]
                .span(),
        };

        ndef
    }

    fn contract_defs() -> Span<ContractDef> {
        [
            ContractDefTrait::new(@"dojo_starter", @"teamVerse")
                .with_writer_of([dojo::utils::bytearray_hash(@"dojo_starter")].span())
        ]
            .span()
    }

    #[test]
    fn test_player_registration() {
        let caller_1 = contract_address_const::<'aji'>();
        let username = 'Aji';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"teamVerse").unwrap();
        let actions_system = ITeamVerseDispatcher { contract_address };

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);
        let player: Player = actions_system.retrieve_player(caller_1);
        println!("username: {}", player.username);
        assert(player.player == caller_1, 'incorrect address');
        assert(player.username == 'Aji', 'incorrect username');
    }

    #[test]
    #[should_panic]
    fn test_player_registration_same_user_name() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'dreamer'>();
        let username = 'Aji';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"teamVerse").unwrap();
        let actions_system = ITeamVerseDispatcher { contract_address };

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username);
    }

    #[test]
    #[should_panic]
    fn test_player_registration_same_user_tries_to_register_twice_with_different_username() {
        let caller_1 = contract_address_const::<'aji'>();
        let username = 'Aji';
        let username1 = 'Ajidokwu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"teamVerse").unwrap();
        let actions_system = ITeamVerseDispatcher { contract_address };

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username1);
    }

    #[test]
    #[should_panic]
    fn test_player_registration_same_user_tries_to_register_twice_with_the_same_username() {
        let caller_1 = contract_address_const::<'aji'>();
        let username = 'Aji';
        let username1 = 'Aji';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"teamVerse").unwrap();
        let actions_system = ITeamVerseDispatcher { contract_address };

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username1);
    }
    #[test]
    fn test_create_game() {
        let caller_1 = contract_address_const::<'aji'>();
        let username = 'Ajidokwu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"teamVerse").unwrap();
        let actions_system = ITeamVerseDispatcher { contract_address };

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        let game_id = actions_system.create_new_game(2);
        assert(game_id == 1, 'Wrong game id');
        println!("game_id: {}", game_id);

        let game: Game = actions_system.retrieve_game(game_id);
        assert(game.created_by == caller_1, 'Wrong creator');
    }

    #[test]
    #[should_panic]
    fn test_create_game_with_one_player() {
        let caller_1 = contract_address_const::<'aji'>();
        let username = 'Ajidokwu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"teamVerse").unwrap();
        let actions_system = ITeamVerseDispatcher { contract_address };

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        let game_id = actions_system.create_new_game(1);
        assert(game_id == 1, 'Wrong game id');
        println!("game_id: {}", game_id);

        let game: Game = actions_system.retrieve_game(game_id);
        assert(game.created_by == caller_1, 'Wrong creator');
    }

    #[test]
    fn test_create_two_games() {
        let caller_1 = contract_address_const::<'aji'>();

        let username = 'Ajidokwu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"teamVerse").unwrap();
        let actions_system = ITeamVerseDispatcher { contract_address };

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_1);
        let _game_id = actions_system.create_new_game(6);

        testing::set_contract_address(caller_1);
        let game_id_1 = actions_system.create_new_game(8);
        assert(game_id_1 == 2, 'Wrong game id');
        println!("game_id: {}", game_id_1);
    }

    #[test]
    #[should_panic]
    fn test_create_game_unregistered_player() {
        let caller_1 = contract_address_const::<'aji'>();

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"teamVerse").unwrap();
        let actions_system = ITeamVerseDispatcher { contract_address };

        testing::set_contract_address(caller_1);
        let game_id = actions_system.create_new_game(2);
        assert(game_id == 1, 'Wrong game id');
        println!("game_id: {}", game_id);
    }


    #[test]
    fn test_join_game() {
        let caller_1 = contract_address_const::<'aji'>();
        let caller_2 = contract_address_const::<'dreamer'>();
        let username = 'Ajidokwu';
        let username1 = 'Dreamer';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"teamVerse").unwrap();
        let actions_system = ITeamVerseDispatcher { contract_address };

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);

        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username1);

        testing::set_contract_address(caller_1);
        let game_id = actions_system.create_new_game(2);
        assert(game_id == 1, 'Wrong game id');
        println!("game_id: {}", game_id);

        let game: Game = actions_system.retrieve_game(game_id);
        assert(game.created_by == caller_1, 'Wrong creator');

        testing::set_contract_address(caller_2);
        actions_system.join_game(game_id);
    }

    #[test]
    fn test_team_creation() {
        let caller_1 = contract_address_const::<'aji'>();

        let username = 'Aji';

        let ndef = namespace_def();

        let mut world = spawn_test_world([ndef].span());

        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"teamVerse").unwrap();

        let actions_system = ITeamVerseDispatcher { contract_address };

        testing::set_contract_address(caller_1);

        let status: bool = actions_system.create_team('Teamverse');

        assert(status == true, 'Team creation failed');
    }

    // New tests for submit_questions function

    #[test]
    fn test_submit_questions_success() {
        let caller_1 = contract_address_const::<'player1'>();
        let username = 'PlayerOne';
        let caller_2 = contract_address_const::<'player2'>();
        let username2 = 'PlayerTwo';
        let zeroAddr = contract_address_const::<0x0>();

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"teamVerse").unwrap();
        let actions_system = ITeamVerseDispatcher { contract_address };

        // Register players
        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);
        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username2);

        // Create a game
        testing::set_contract_address(caller_1);
        let game_id = actions_system.create_new_game(2);

        // Verify next_player is set to caller_1
        let game: Game = actions_system.retrieve_game(game_id);
        assert(game.next_player == caller_1, 'next_player should be caller_1');

        let statement1 = 'Statement One';
        let statement2 = 'Statement Two';
        let statement3 = 'Statement Three';
        let lie_index = 1; // Statement 2 is the lie

        // Submit questions as the next_player (caller_1)
        testing::set_contract_address(caller_1);
        actions_system.submit_questions(game_id, statement1, statement2, statement3, lie_index);
        let game: Game = actions_system.retrieve_game(game_id);
        let round_questions: RoundQuestions = actions_system.retrieve_submittedQuestions(game_id);

        assert(round_questions.game_id == game_id, 'Game ID should match');
        assert(round_questions.round == game.current_round, 'Current round should match');
        assert(round_questions.player == caller_1, 'player should be caller1');
        assert(round_questions.statement1 == statement1, 'Questions should match');
        assert(round_questions.statement2 == statement2, 'Questions should match');
        assert(round_questions.statement3 == statement3, 'Questions should match');
        assert(round_questions.lie_index == lie_index, 'lie_index should match');
        assert(game.next_player == zeroAddr, 'Should revert to zeroAddr');
    }

    #[test]
    #[should_panic] //( expected: 'STATEMENT2 CANNOT BE EMPTY')
    fn test_submit_questions_invalid_statement() {
        let caller_1 = contract_address_const::<'player1'>();
        let username = 'PlayerOne';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"teamVerse").unwrap();
        let actions_system = ITeamVerseDispatcher { contract_address };

        // Register player and create game
        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);
        let game_id = actions_system.create_new_game(10);

        let statement1 = 'Statement One';
        let statement2 = 0; // Invalid empty statement
        let statement3 = 'Statement Three';
        let lie_index = 1;

        // Attempt to submit questions with an empty statement
        testing::set_contract_address(caller_1);
        actions_system.submit_questions(game_id, statement1, statement2, statement3, lie_index);
    }

    #[test]
    #[should_panic] // (expected: 'INVALID LIE INDEX')
    fn test_submit_questions_invalid_lie_index() {
        let caller_1 = contract_address_const::<'player1'>();
        let username = 'PlayerOne';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"teamVerse").unwrap();
        let actions_system = ITeamVerseDispatcher { contract_address };

        // Register player and create game
        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);
        let game_id = actions_system.create_new_game(11);

        let statement1 = 'Statement One';
        let statement2 = 'Statement Two';
        let statement3 = 'Statement Three';
        let lie_index = 3; // Invalid lie index must  be 0 - 2

        // Attempt to submit questions with an invalid lie index
        testing::set_contract_address(caller_1);
        actions_system.submit_questions(game_id, statement1, statement2, statement3, lie_index);
    }

    #[test]
    #[should_panic] // (expected: 'NOT YOUR TURN')
    fn test_submit_questions_not_your_turn() {
        let caller_1 = contract_address_const::<'player1'>();
        let username = 'PlayerOne';
        let caller_2 = contract_address_const::<'player2'>();
        let username2 = 'PlayerTwo';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"teamVerse").unwrap();
        let actions_system = ITeamVerseDispatcher { contract_address };

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);
        testing::set_contract_address(caller_2);
        actions_system.register_new_player(username2);

        testing::set_contract_address(caller_1);
        let game_id = actions_system.create_new_game(13);

        let statement1 = 'Statement One';
        let statement2 = 'Statement Two';
        let statement3 = 'Statement Three';
        let lie_index = 1;

        // Attempt to submit questions as caller_2 (not the next player)
        testing::set_contract_address(caller_2);
        actions_system.submit_questions(game_id, statement1, statement2, statement3, lie_index);
    }

    #[test]
    #[should_panic] // (expected: 'GAME NOT PENDING')
    fn test_submit_questions_game_not_pending() {
        let caller_1 = contract_address_const::<'player1'>();
        let username = 'PlayerOne';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"teamVerse").unwrap();
        let actions_system = ITeamVerseDispatcher { contract_address };

        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);
        let game_id = actions_system.create_new_game(2);

        actions_system.end_game(game_id, caller_1);

        let statement1 = 'Statement One';
        let statement2 = 'Statement Two';
        let statement3 = 'Statement Three';
        let lie_index = 1;

        // Attempt to submit questions while game is Pending
        testing::set_contract_address(caller_1);
        actions_system.submit_questions(game_id, statement1, statement2, statement3, lie_index);
    }
}
