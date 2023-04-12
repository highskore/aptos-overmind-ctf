module overmind::nftango {
    use std::option::Option;
    use std::string::String;

    use aptos_framework::account;

    use aptos_token::token::TokenId;

    //
    // Errors
    //
    const ERROR_NFTANGO_STORE_EXISTS: u64 = 0;
    const ERROR_NFTANGO_STORE_DOES_NOT_EXIST: u64 = 1;
    const ERROR_NFTANGO_STORE_IS_ACTIVE: u64 = 2;
    const ERROR_NFTANGO_STORE_IS_NOT_ACTIVE: u64 = 3;
    const ERROR_NFTANGO_STORE_HAS_AN_OPPONENT: u64 = 4;
    const ERROR_NFTANGO_STORE_DOES_NOT_HAVE_AN_OPPONENT: u64 = 5;
    const ERROR_NFTANGO_STORE_JOIN_AMOUNT_REQUIREMENT_NOT_MET: u64 = 6;
    const ERROR_NFTS_ARE_NOT_IN_THE_SAME_COLLECTION: u64 = 7;
    const ERROR_NFTANGO_STORE_DOES_NOT_HAVE_DID_CREATOR_WIN: u64 = 8;
    const ERROR_NFTANGO_STORE_HAS_CLAIMED: u64 = 9;
    const ERROR_NFTANGO_STORE_IS_NOT_PLAYER: u64 = 10;
    const ERROR_VECTOR_LENGTHS_NOT_EQUAL: u64 = 11;

    //
    // Data structures
    //
    struct NFTangoStore has key {
        creator_token_id: TokenId,
        // The number of NFTs (one more more) from the same collection that the opponent needs to bet to enter the game
        join_amount_requirement: u64,
        opponent_address: Option<address>,
        opponent_token_ids: vector<TokenId>,
        active: bool,
        has_claimed: bool,
        did_creator_win: Option<bool>,
        signer_capability: account::SignerCapability
    }

    //
    // Assert functions
    //
    public fun assert_nftango_store_exists (
        account_address: address,
    ) {
        assert!(exists<NFTangoStore>(account_address), std::error::invalid_state(ERROR_NFTANGO_STORE_DOES_NOT_EXIST));
    }

    public fun assert_nftango_store_does_not_exist(
        account_address: address,
    ) {
        // assert that `NFTangoStore` does not exist
        assert!(!exists<NFTangoStore>(account_address), std::error::invalid_state(ERROR_NFTANGO_STORE_EXISTS));
    }

    public fun assert_nftango_store_is_active(
        account_address: address,
    ) acquires NFTangoStore {
        // assert that `NFTangoStore.active` is active
        let nftango_store = borrow_global<NFTangoStore>(account_address);
        assert!(nftango_store.active, std::error::invalid_argument(ERROR_NFTANGO_STORE_IS_NOT_ACTIVE));
    }

    public fun assert_nftango_store_is_not_active(
        account_address: address,
    ) acquires NFTangoStore {
        // assert that `NFTangoStore.active` is not active
        let nftango_store = borrow_global<NFTangoStore>(account_address);
        assert!(!nftango_store.active, std::error::invalid_argument(ERROR_NFTANGO_STORE_IS_ACTIVE));
    }

    public fun assert_nftango_store_has_an_opponent(
        account_address: address,
    ) acquires NFTangoStore {
        // assert that `NFTangoStore.opponent_address` is set
        let nftango_store = borrow_global<NFTangoStore>(account_address);
        assert!(std::option::is_some(&nftango_store.opponent_address), std::error::invalid_argument(ERROR_NFTANGO_STORE_DOES_NOT_HAVE_AN_OPPONENT));
    }

    public fun assert_nftango_store_does_not_have_an_opponent(
        account_address: address,
    ) acquires NFTangoStore {
        // assert that `NFTangoStore.opponent_address` is not set
        let nftango_store = borrow_global<NFTangoStore>(account_address);
        assert!(std::option::is_none(&nftango_store.opponent_address), std::error::invalid_argument(ERROR_NFTANGO_STORE_HAS_AN_OPPONENT));
    }

    public fun assert_nftango_store_join_amount_requirement_is_met(
        game_address: address,
        token_ids: vector<TokenId>,
    ) acquires NFTangoStore {
        // assert that `NFTangoStore.join_amount_requirement` is met
        let nftango_store = borrow_global<NFTangoStore>(game_address);
        assert!(nftango_store.join_amount_requirement == std::vector::length(&token_ids), std::error::invalid_argument(ERROR_NFTANGO_STORE_JOIN_AMOUNT_REQUIREMENT_NOT_MET));
    }

    public fun assert_nftango_store_has_did_creator_win(
        game_address: address,
    ) acquires NFTangoStore {
        // assert that `NFTangoStore.did_creator_win` is set
        let nftango_store = borrow_global<NFTangoStore>(game_address);
        assert!(std::option::is_some(&nftango_store.did_creator_win), std::error::invalid_argument(ERROR_NFTANGO_STORE_DOES_NOT_HAVE_DID_CREATOR_WIN));
    }

    public fun assert_nftango_store_has_not_claimed(
        game_address: address,
    ) acquires NFTangoStore {
        // assert that `NFTangoStore.has_claimed` is false
        let nftango_store = borrow_global<NFTangoStore>(game_address);
        assert!(!nftango_store.has_claimed, std::error::invalid_argument(ERROR_NFTANGO_STORE_HAS_CLAIMED));
    }

    public fun assert_nftango_store_is_player(account_address: address, game_address: address) acquires NFTangoStore {
        // assert that `account_address` is either the equal to `game_address` or `NFTangoStore.opponent_address`
        let nftango_store = borrow_global<NFTangoStore>(game_address);
        assert!(account_address == game_address || &account_address == std::option::borrow(&nftango_store.opponent_address),  std::error::invalid_argument(ERROR_NFTANGO_STORE_IS_NOT_PLAYER));
    }

    public fun assert_vector_lengths_are_equal(creator: vector<address>,
                                               collection_name: vector<String>,
                                               token_name: vector<String>,
                                               property_version: vector<u64>) {
        // assert all vector lengths are equal
        assert!(std::vector::length(&creator) == std::vector::length(&collection_name) && std::vector::length(&creator) == std::vector::length(&token_name) && std::vector::length(&token_name) == std::vector::length(&property_version), std::error::invalid_argument(ERROR_VECTOR_LENGTHS_NOT_EQUAL));
    }

    //
    // Entry functions
    //
    public entry fun initialize_game(
        account: &signer,
        creator: address,
        collection_name: String,
        token_name: String,
        property_version: u64,
        join_amount_requirement: u64
    ) {
        // assert_nftango_store_does_not_exist
        assert_nftango_store_does_not_exist(std::signer::address_of(account));        

        // create a seed
        let seed = std::vector::empty<u8>();
        // add initialize_game params to the seed
        std::vector::append(&mut seed, std::bcs::to_bytes(&creator));
        std::vector::append(&mut seed, std::bcs::to_bytes(&collection_name));
        std::vector::append(&mut seed, std::bcs::to_bytes(&token_name));
        std::vector::append(&mut seed, std::bcs::to_bytes(&property_version));
        std::vector::append(&mut seed, std::bcs::to_bytes(&join_amount_requirement));

        // create resource account
        let (resource_account, capability) = account::create_resource_account(account, seed);

        // token::create_token_id_raw
        let token_id = aptos_token::token::create_token_id_raw(creator, collection_name, token_name, property_version);
    
        // opt in to direct transfer for resource account
        aptos_token::token::opt_in_direct_transfer(&resource_account, true);

        // transfer NFT to resource account
        aptos_token::token::transfer(account, token_id, std::signer::address_of(&resource_account), 1);

        // move_to resource `NFTangoStore` to account signer
        move_to(account, NFTangoStore {
            creator_token_id: token_id,
            join_amount_requirement,
            opponent_address: std::option::none(),
            opponent_token_ids: std::vector::empty<TokenId>(),
            active: true,
            has_claimed: false,
            did_creator_win: std::option::none(),
            signer_capability: capability
        });
    }

    public entry fun cancel_game(
        account: &signer,
    ) acquires NFTangoStore {
        // run assert_nftango_store_exists
        assert_nftango_store_exists(std::signer::address_of(account));

        // run assert_nftango_store_is_active
        assert_nftango_store_is_active(std::signer::address_of(account));

        // run assert_nftango_store_does_not_have_an_opponent
        assert_nftango_store_does_not_have_an_opponent(std::signer::address_of(account));

        // opt in to direct transfer for account
        aptos_token::token::opt_in_direct_transfer(account, true);

        // transfer NFT to account address
        let nftango_store = borrow_global_mut<NFTangoStore>(std::signer::address_of(account));
        aptos_token::token::transfer(&(aptos_framework::account::create_signer_with_capability(&nftango_store.signer_capability)), nftango_store.creator_token_id, std::signer::address_of(account), 1);

        // set `NFTangoStore.active` to false
        nftango_store.active = false;
    }

    public fun join_game(
        account: &signer,
        game_address: address,
        creators: vector<address>,
        collection_names: vector<String>,
        token_names: vector<String>,
        property_versions: vector<u64>,
    ) acquires NFTangoStore {
        // run assert_vector_lengths_are_equal
        assert_vector_lengths_are_equal(creators, collection_names, token_names, property_versions);

        // loop through token_names and create token_ids vector<TokenId>
        let token_ids = std::vector::empty<TokenId>();
        let i = 0;
        while (i < std::vector::length(&token_names)) {
            // token::create_token_id_raw
            let token_id = aptos_token::token::create_token_id_raw(*std::vector::borrow(&creators, i), *std::vector::borrow(&collection_names, i), *std::vector::borrow(&token_names, i), *std::vector::borrow(&property_versions, i));
            // append token_id to token_ids
            std::vector::push_back(&mut token_ids, token_id);
            i = i + 1;
        };

        // run assert_nftango_store_exists
        assert_nftango_store_exists(game_address);

        // run assert_nftango_store_is_active
        assert_nftango_store_is_active(game_address);

        // run assert_nftango_store_does_not_have_an_opponent
        assert_nftango_store_does_not_have_an_opponent(game_address);

        // run assert_nftango_store_join_amount_requirement_is_met
        assert_nftango_store_join_amount_requirement_is_met(game_address, token_ids);

        let nftango_store = borrow_global_mut<NFTangoStore>(game_address);

        // loop through token_ids and transfer each NFT to the resource account
        let i = 0;
        while (i < std::vector::length(&token_ids)) {
            // opt in to direct transfer for account
            aptos_token::token::opt_in_direct_transfer(account, true);

            // transfer NFT to game_address
            aptos_token::token::transfer(account, *std::vector::borrow(&token_ids, i), aptos_framework::account::get_signer_capability_address(&nftango_store.signer_capability), 1);
            i = i + 1;
        };

        // set `NFTangoStore.opponent_address` to account_address
        nftango_store.opponent_address = std::option::some(std::signer::address_of(account));

        // set `NFTangoStore.opponent_token_ids` to token_ids
        nftango_store.opponent_token_ids = token_ids;
    }

    public entry fun play_game(account: &signer, did_creator_win: bool) acquires NFTangoStore {
        // run assert_nftango_store_exists
        assert_nftango_store_exists(std::signer::address_of(account));

        // run assert_nftango_store_is_active
        assert_nftango_store_is_active(std::signer::address_of(account));

        // run assert_nftango_store_has_an_opponent
        assert_nftango_store_has_an_opponent(std::signer::address_of(account));

        // set `NFTangoStore.did_creator_win` to did_creator_win
        let nftango_store = borrow_global_mut<NFTangoStore>(std::signer::address_of(account));
        nftango_store.did_creator_win = std::option::some(did_creator_win);

        // set `NFTangoStore.active` to false
        nftango_store.active = false;
    }

    public entry fun claim(account: &signer, game_address: address) acquires NFTangoStore {
        // run assert_nftango_store_exists
        assert_nftango_store_exists(game_address);

        // run assert_nftango_store_is_not_active
        assert_nftango_store_is_not_active(game_address);

        // run assert_nftango_store_has_not_claimed
        assert_nftango_store_has_not_claimed(game_address);

        // run assert_nftango_store_is_player
        assert_nftango_store_is_player(std::signer::address_of(account), game_address);

        // if the player won, send them all the NFTs
        let nftango_store = borrow_global_mut<NFTangoStore>(game_address);

        // if the winner address is the same as the account's address, send them all the NFTs
        if (*std::option::borrow(&nftango_store.did_creator_win) && std::signer::address_of(account) == game_address || !*std::option::borrow(&nftango_store.did_creator_win) && std::signer::address_of(account) != game_address) {
            let i = 0;
            while (i < std::vector::length(&nftango_store.opponent_token_ids)) {
                // opt in to direct transfer for account
                aptos_token::token::opt_in_direct_transfer(account, true);
                // transfer NFT to account address
                aptos_token::token::transfer(&(aptos_framework::account::create_signer_with_capability(&nftango_store.signer_capability)), *std::vector::borrow(&nftango_store.opponent_token_ids, i), std::signer::address_of(account), 1);
                i = i + 1;
            };
            aptos_token::token::transfer(&(aptos_framework::account::create_signer_with_capability(&nftango_store.signer_capability)), nftango_store.creator_token_id, std::signer::address_of(account), 1);
        };
        // set `NFTangoStore.has_claimed` to true
        nftango_store.has_claimed = true;
    }
}