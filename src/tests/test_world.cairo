#[cfg(test)]
mod tests {
    use dojo::model::{ModelStorage, ModelStorageTest};
    use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{
        ContractDef, ContractDefTrait, NamespaceDef, TestResource, WorldStorageTestTrait,
        spawn_test_world,
    };
    use dojo_starter::interfaces::ITeamVerse::{ITeamVerseDispatcher, ITeamVerseDispatcherTrait};
    use dojo_starter::model::game_model::{Game, GameCounter, GameStatus, m_Game, m_GameCounter};
    use dojo_starter::model::player_model::{
        AddressToUsername, Player, PlayerStatements, Statement, UsernameToAddress,
        m_AddressToUsername, m_Player, m_PlayerStatements, m_Statement, m_UsernameToAddress,
    };
    use dojo_starter::systems::teamVerse::teamVerse;
    use starknet::{contract_address_const, get_caller_address, testing};


    fn namespace_def() -> NamespaceDef {
        let ndef = NamespaceDef {
            namespace: "dojo_starter",
            resources: [
                TestResource::Model(m_Player::TEST_CLASS_HASH),
                TestResource::Model(m_UsernameToAddress::TEST_CLASS_HASH),
                TestResource::Model(m_AddressToUsername::TEST_CLASS_HASH),
                TestResource::Model(m_Game::TEST_CLASS_HASH),
                TestResource::Model(m_GameCounter::TEST_CLASS_HASH),
                TestResource::Model(m_Statement::TEST_CLASS_HASH),
                TestResource::Model(m_PlayerStatements::TEST_CLASS_HASH),
                TestResource::Event(teamVerse::e_PlayerCreated::TEST_CLASS_HASH),
                TestResource::Event(teamVerse::e_GameCreated::TEST_CLASS_HASH),
                TestResource::Event(teamVerse::e_StatementSetSubmitted::TEST_CLASS_HASH),
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
    };

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
    };

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
    };

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
    };

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
    };
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
    };

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
    };

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
    };

    // Tests for 2 Truths and a Lie
    #[test]
    fn test_submit_statement_set() {
        let caller_1 = contract_address_const::<'aji'>();
        let username = 'Ajidokwu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"teamVerse").unwrap();
        let actions_system = ITeamVerseDispatcher { contract_address };

        // Register player and create a game
        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);
        let game_id = actions_system.create_new_game(2);

        // Submit a statement set with 2 truths and 1 lie
        let statements = array!['I have been to Paris', 'I can speak French', 'I am a doctor'];
        let lie_index = 3_u8; // The third statement is the lie

        testing::set_contract_address(caller_1);
        actions_system.submit_statement_set(game_id, 1, statements, lie_index);

        // Verify the statements were stored correctly
        let statement1 = actions_system.get_statement(caller_1, 1, 1);
        let statement2 = actions_system.get_statement(caller_1, 1, 2);
        let statement3 = actions_system.get_statement(caller_1, 1, 3);

        assert(statement1.content == 'I have been to Paris', 'Wrong statement 1');
        assert(statement2.content == 'I can speak French', 'Wrong statement 2');
        assert(statement3.content == 'I am a doctor', 'Wrong statement 3');

        assert(statement1.is_truth == true, 'Statement 1 should be true');
        assert(statement2.is_truth == true, 'Statement 2 should be true');
        assert(statement3.is_truth == false, 'Statement 3 should be false');

        // Verify player statement tracker was updated
        let player_statements = actions_system.get_player_statements(caller_1, game_id);
        assert(player_statements.sets_submitted == 1, 'Should have 1 set submitted');
        assert(player_statements.has_submitted == true, 'Should be marked as submitted');
    };

    #[test]
    fn test_submit_multiple_statement_sets() {
        let caller_1 = contract_address_const::<'aji'>();
        let username = 'Ajidokwu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"teamVerse").unwrap();
        let actions_system = ITeamVerseDispatcher { contract_address };

        // Register player and create a game
        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);
        let game_id = actions_system.create_new_game(2);

        // Submit first statement set
        let statements1 = array!['I have been to Paris', 'I can speak French', 'I am a doctor'];
        let lie_index1 = 3_u8;

        testing::set_contract_address(caller_1);
        actions_system.submit_statement_set(game_id, 1, statements1, lie_index1);

        // Submit second statement set
        let statements2 = array!['I love pizza', 'I have a pet snake', 'I can play piano'];
        let lie_index2 = 2_u8;

        testing::set_contract_address(caller_1);
        actions_system.submit_statement_set(game_id, 2, statements2, lie_index2);

        // Verify player statement tracker was updated
        let player_statements = actions_system.get_player_statements(caller_1, game_id);
        assert(player_statements.sets_submitted == 2, 'Should have 2 sets submitted');
    };

    #[test]
    fn test_submit_max_statement_sets() {
        let caller_1 = contract_address_const::<'aji'>();
        let username = 'Ajidokwu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"teamVerse").unwrap();
        let actions_system = ITeamVerseDispatcher { contract_address };

        // Register player and create a game
        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);
        let game_id = actions_system.create_new_game(2);

        // Submit three statement sets (maximum allowed)
        for i in 1..4 {
            let statements = array![
                'Statement A for set ' + i.into(),
                'Statement B for set ' + i.into(),
                'Statement C for set ' + i.into(),
            ];
            let lie_index = 3_u8;

            testing::set_contract_address(caller_1);
            actions_system.submit_statement_set(game_id, i, statements, lie_index);
        }

        // Verify player statement tracker shows 3 sets submitted
        let player_statements = actions_system.get_player_statements(caller_1, game_id);
        assert(player_statements.sets_submitted == 3, 'Should have 3 sets submitted');
    };

    #[test]
    #[should_panic(expected: ('MAX SETS SUBMITTED',))]
    fn test_exceed_max_statement_sets() {
        let caller_1 = contract_address_const::<'aji'>();
        let username = 'Ajidokwu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"teamVerse").unwrap();
        let actions_system = ITeamVerseDispatcher { contract_address };

        // Register player and create a game
        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);
        let game_id = actions_system.create_new_game(2);

        // Submit three statement sets (maximum allowed)
        for i in 1..4 {
            let statements = array![
                'Statement A for set ' + i.into(),
                'Statement B for set ' + i.into(),
                'Statement C for set ' + i.into(),
            ];
            let lie_index = 3_u8;

            testing::set_contract_address(caller_1);
            actions_system.submit_statement_set(game_id, i, statements, lie_index);
        }

        // Try to submit a fourth set (should fail)
        let statements = array!['Extra A', 'Extra B', 'Extra C'];
        let lie_index = 2_u8;

        testing::set_contract_address(caller_1);
        actions_system.submit_statement_set(game_id, 1, statements, lie_index);
    };

    #[test]
    #[should_panic(expected: ('MUST PROVIDE 3 STATEMENTS',))]
    fn test_submit_invalid_statement_count() {
        let caller_1 = contract_address_const::<'aji'>();
        let username = 'Ajidokwu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"teamVerse").unwrap();
        let actions_system = ITeamVerseDispatcher { contract_address };

        // Register player and create a game
        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);
        let game_id = actions_system.create_new_game(2);

        // Try to submit only 2 statements (should fail)
        let statements = array!['Statement A', 'Statement B'];
        let lie_index = 2_u8;

        testing::set_contract_address(caller_1);
        actions_system.submit_statement_set(game_id, 1, statements, lie_index);
    }

    #[test]
    #[should_panic(expected: ('STATEMENT CANNOT BE EMPTY',))]
    fn test_submit_empty_statement() {
        let caller_1 = contract_address_const::<'aji'>();
        let username = 'Ajidokwu';

        let ndef = namespace_def();
        let mut world = spawn_test_world([ndef].span());
        world.sync_perms_and_inits(contract_defs());

        let (contract_address, _) = world.dns(@"teamVerse").unwrap();
        let actions_system = ITeamVerseDispatcher { contract_address };

        // Register player and create a game
        testing::set_contract_address(caller_1);
        actions_system.register_new_player(username);
        let game_id = actions_system.create_new_game(2);

        // Try to submit with an empty statement (should fail)
        let statements = array!['Statement A', '', 'Statement C'];
        let lie_index = 2_u8;

        testing::set_contract_address(caller_1);
        actions_system.submit_statement_set(game_id, 1, statements, lie_index);
    };
}
