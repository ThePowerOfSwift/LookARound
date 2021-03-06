//
//  PlaceRequest.swift
//  LookARound
//
//  Created by Angela Yu on 10/12/17.
//  Copyright © 2017 LookARound. All rights reserved.
//

import Foundation
import FacebookCore
import CoreLocation
import SwiftyJSON

enum sortMethod: Int {
    case checkins = 0
    case friends = 1
}


struct PlaceSearch {
    func fetchPlaces(with categories:[FilterCategory], success: @escaping ([Place]?)->(), failure: @escaping (Error)->()) -> Void {
        var request = PlaceSearchRequest()
        request.graphPath = graphPathString(categories: categories)
        
        let searchConnection = GraphRequestConnection()
        searchConnection.add(request) { (response, result: GraphRequestResult) in
            switch result {
            case .success(let response):
                success(response.places)
            case .failed(let error):
                failure(error)
            }
        }
        searchConnection.start()
    }
    
    func sortPlaces(places: [Place], by method: sortMethod) -> [Place] {
        switch method {
        case .checkins:
            let sortedPlaces = places.sorted(by: {
                guard let firstCheckins = $0.checkins else {
                    return true
                }
                guard let secondCheckins = $1.checkins else {
                    return true
                }
                return firstCheckins > secondCheckins
            })
            return sortedPlaces
        case .friends:
            let sortedPlaces = places.sorted(by: {
                guard let firstFriends = $0.contextCount else {
                    return false
                }
                guard let secondFriends = $1.contextCount else {
                    return false
                }
                return firstFriends > secondFriends
            })
            return sortedPlaces
        }
    }
}

struct MyProfileRequest: GraphRequestProtocol {
    struct Response: GraphResponseProtocol {
        var id: String
        var name: String
        var photoURL: String
        
        init(rawResponse: Any?) {
            // Decode JSON from rawResponse into other properties here.
            let json = JSON(rawResponse!)
            print(json)
            id = json["id"].stringValue
            name = json["name"].stringValue
            photoURL = json["picture"]["data"]["url"].stringValue
            
            print(id)
            print(name)
            print(photoURL)
        }
    }
    
    var graphPath = "/me"
    var parameters: [String : Any]? = ["fields": "id, name, picture{url}"]
    var accessToken = AccessToken.current
    var httpMethod: GraphRequestHTTPMethod = .GET
    var apiVersion: GraphAPIVersion = .defaultVersion
}

func graphPathString(categories : [FilterCategory]) -> String {
    var categoriesStr = ""
    for category in categories {
        categoriesStr += "%22\(FilterCategorySearchString(category: category))%22,"
    }
    let graphPath = "/search?type=place&center=37.4816734,-122.1556204&categories=[" + categoriesStr + "]"
    
    return graphPath
}

/// Use PlaceSearch().fetchPlaces instead of using this directly.
private struct PlaceSearchRequest: GraphRequestProtocol {
    
    // GraphPath documentation at https://developers.facebook.com/docs/places/web/search
    var graphPath: String = "" // This string will be populated with the graphPathString function which is called by PlaceSearch().fetchPlaces.
    
    // Places available fields documentation at https://developers.facebook.com/docs/places/fields
    var parameters: [String: Any]? = ["fields": "name, about, id, location, context, engagement, checkins, picture, cover"]
    
    // Logged in and Not-Logged-In access documented at https://developers.facebook.com/docs/places/access-tokens
    var accessToken = AccessToken.current
    var httpMethod: GraphRequestHTTPMethod = .GET
    var apiVersion: GraphAPIVersion = .defaultVersion
    
    typealias Response = PlaceSearchResponse
}

private struct PlaceSearchResponse: GraphResponseProtocol {
    var places: [Place]
    
    init(rawResponse: Any?) {
        // Decode JSON from rawResponse into other properties here.
        /* Sample API response for Angela Yu searching at Builing 20:
         use JSON viewer to collapse and expand tree here https://codebeautify.org/jsonviewer/cb147a70
         */
        let json = JSON(rawResponse!)
        // print(json)
        places = []
        for spot in json["data"].arrayValue {
            let placeID = spot["id"].intValue
            let placeName = spot["name"].stringValue
            let placeLat = spot["location"]["latitude"].doubleValue
            let placeLon = spot["location"]["longitude"].doubleValue
            
            let thisPlace = Place(id: Int64(placeID), name: placeName, latitude: placeLat, longitude: placeLon)
            
            thisPlace.address = spot["address"].stringValue
            thisPlace.about = spot["about"].stringValue
            thisPlace.picture = spot["picture"]["data"]["url"].stringValue
            thisPlace.context = spot["context"]["friends_who_like"]["summary"]["social_sentence"].stringValue
            thisPlace.contextCount = spot["context"]["friends_who_like"]["summary"]["total_count"].intValue
            thisPlace.checkins = spot["checkins"].intValue
            thisPlace.engagement = spot["engagement"]["social_sentence"].stringValue
            thisPlace.likes = spot["engagement"]["count"].intValue
            places.append(thisPlace)
        }
    }
}
    
    /* Objective-C version
     FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
     initWithGraphPath:@"/search"
     parameters:@{ @"type": @"place",@"center": @"37.4816734,-122.1556204",@"categories": @"["FOOD_BEVERAGE","FITNESS_RECREATION","SHOPPING_RETAIL"]",@"fields": @"name,about,id,location,context,engagement,checkins,picture,photos,cover",}
     HTTPMethod:@"GET"];
     [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
     // Insert your code here
     }];
     
     Android SDK version
 GraphRequest request = GraphRequest.newGraphPathRequest(
 accessToken,
 "/search",
 new GraphRequest.Callback() {
 @Override
 public void onCompleted(GraphResponse response) {
 // Insert your code here
 }
 });
 
 Bundle parameters = new Bundle();
 parameters.putString("type", "place");
 parameters.putString("center", "37.4816734,-122.1556204");
 parameters.putString("categories", "["FOOD_BEVERAGE","FITNESS_RECREATION","SHOPPING_RETAIL"]");
 parameters.putString("fields", "name,about,id,location,context,engagement,checkins,picture,photos,cover");
 request.setParameters(parameters);
 request.executeAsync();
 */

