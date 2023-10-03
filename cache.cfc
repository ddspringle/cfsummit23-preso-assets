component {

	property name="entity" type="string" default="";

	/**
	* @displayname 	init
	* @description 	I initialize this singleton for a specific entity
	* @entity 		I am the entity (cache region) to use
	* @return		this
	*/
	public function init(
		required string entity
	) {
		// set the entity property
		setEntity( arguments.entity & '_' );

		// return this singleton
		return this;
	}


	/**
	* @displayname 	get
	* @description 	I get an entity from the entities cache
	* @itemName 	I am the name of the item stored in cache
	* @return		any
	*/
	publc any function get(
		required string itemName
	) {
		// do a standard cacheGet() for this entity prefix
		return cacheGet( getEntity() & arguments.itemName );
	}


	/**
	* @displayname 	set
	* @description 	I put an entity into the entities cache
	* @itemName 	I am the name of the item stored in cache
	* @item 		I am the item to store in the cache (struct, array, object, string, etc.)
	* @cacheTime 	I am a human readable number of days, hours, minutes and seconds in the format: Xd Xh Xm Xs
	*/
	public void function set(
		required string itemName,
		required any item,
		string cacheTime = "15m"
	) {
		// get the timespan for the cacheTime passed in
		var ttl = getTimespanFromCacheTime( arguments.cacheTime );

		// put the item into the cache
		cachePut(
			getEntity() & arguments.itemName,
			arguments.item,
			ttl,
			( ttl / 2 )
		);
	}


	/**
	* @displayname 	clear
	* @description 	I clear an entity item from the cache
	* @itemName 	I am the name of the item to clear from the cache
	*/
	public void function clear(
		required string itemName
	) {
		cacheClear( getEntity() & arguments.itemName );
	}


	/**
	* @displayname 	clearAll
	* @description 	I clear all entity items from the cache
	* @itemName 	I am the name of the item to clear from the cache
	*/
	public void function clearAll() {

		// loop through all the cached items
		for( var id in cacheGetAllIds() ) {

			// check if this item matches the entity prefix
			if( findNoCase( getEntity(), id ) ) {
				// it does, clear it
				clear( id );
			}
		}

	}


	/**
	* @displayname 	put
	* @description 	I am an alias function for set()
	* @itemName 	I am the name of the item stored in cache
	* @item 		I am the item to store in the cache (struct, array, object, string, etc.)
	* @cacheTime 	I am a human readable number of days, hours, minutes and seconds in the format: Xd Xh Xm Xs
	*/
	public void function put(
		required string itemName,
		required any item,
		string cacheTime = "15m"
	) {
		set( argumentCollection = arguments );
	}


	/**
	* @displayname 	getTimespanFromCacheTime
	* @description 	I convert the human readable cacheTime into a CF usable timespan
	* @cacheTime 	I am a human readable number of days, hours, minutes and seconds in the format: Xd Xh Xm Xs
	* @return		struct
	*/
	public struct function getTimespanFromCacheTime(
		required string cacheTime
	) {

		// get the cacheTime timespan from cache
		var timespan = get( listFirst( cgi.server_name, '.' ) & '_' & arguments.cacheTime & '_timespan' );

		// check if we have it in cache
		if( !isNull( timespan ) ) {

			// we do, return the timespan
			return timespan;

		}

		// create a 365 day timespan value to use for caching
		var ttl = createTimespan( 365, 0, 0, 0 );

		// get the zero timespan from cache
		timespan = get( listFirst( cgi.server_name, '.' ) & '_zero_timespan' );

		// check that we have data in the cache
		if( isNull( timespan ) ) {

			// we don't, create a timespan struct
			timespan = {
				'd' = 0,
				'h' = 0,
				'm' = 0,
				's' = 0
			};

			// and put the zero timespan struct in the cache for next use
			cachePut(
				listFirst( cgi.server_name, '.' ) & '_zero_timespan',
				timespan,
				ttl,
				( ttl / 2 )
			);

		}

		// loop through any space separated elements in cacheTime
		for( var element in listToArray( arguments.cacheTime, ' ' ) ) {

			// switch on the letter d, h, m or s in the cacheTime element
			// and add any values to the appropriate day, hour, mnute and second value
			switch( right( element, 1 ) ) {

				case 'd':
					timespan[ 'd' ] += val( element );
				break;

				case 'h':
					timespan[ 'h' ] += val( element );
				break;

				case 'm':
					timespan[ 'm' ] += val( element );
				break;

				case 's':
					timespan[ 's' ] += val( element );
				break;
			}
		}

		// create a timespan value from the timespan struct
		timespan = createTimespan( timespan[ 'd' ], timespan[ 'h' ], timespan[ 'm' ], timespan[ 's' ] );

		// store that value in the cache so it doesn't have to be recalculated later
		cachePut(
			listFirst( cgi.server_name, '.' ) & '_' & arguments.cacheTime & '_timespan',
			timespan,
			ttl,
			( ttl / 2 )
		);

		// return the timespan
		return timespan;
	}
}