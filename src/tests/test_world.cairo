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
    use dojo_starter::model::game_model::{Game, m_Game, GameStatus, GameCounter, m_GameCounter};

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
                TestResource::Event(teamVerse::e_PlayerCreated::TEST_CLASS_HASH),
                TestResource::Event(teamVerse::e_GameCreated::TEST_CLASS_HASH),
                TestResource::Event(teamVerse::e_PlayerJoined::TEST_CLASS_HASH),
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
}
