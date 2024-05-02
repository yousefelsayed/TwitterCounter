//
//  TwitterCharactersCounterViewController.swift
//  TwitterCounter
//
//  Created by Yousef Elsayed on 30/04/2024.
//

import UIKit
import TWTextEditorSDK
import OAuthSwift

class TwitterCharactersCounterViewController: UIViewController {
    
    // Outlets for the text editor and character count labels
    @IBOutlet weak var twTextView: TWTextEditorView!
    @IBOutlet weak var typedCharactersLabel: CounterLabel!
    @IBOutlet weak var remainingCharactersLabel: CounterLabel!
    
    // Network service for making HTTP requests
    private var networkService: NetworkService!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the navigation bar
        setUpNavBar()
        
        // Assign delegate for text view events
        twTextView.viewDelegate = self
        
        // Enable tap-to-hide keyboard behavior
        hideKeyboardWhenTappedAround()
        
        // Initialize the network service
        networkService = URLSessionNetworkService()
    }
    
    // Set up the navigation bar with custom title and back button
    private func setUpNavBar() {
        // Set a blank back button title to maintain default back functionality
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        // Customize navigation bar appearance
        let tintColor = UIColor(red: 0.11, green: 0.129, blue: 0.122, alpha: 1)
        navigationController?.navigationBar.tintColor = tintColor
        
        // Set navigation bar title and its attributes
        navigationItem.title = "Twitter Character Count"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: tintColor,
            .font: UIFont.twFontMediumWithSize(size: 18)
        ]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes
    }
    
    // Action to copy the current text to the clipboard
    @IBAction func copyTextButtonAction(_ sender: Any) {
        twTextView.copyCurrentText()
    }
    
    // Action to clear the text in the editor
    @IBAction func clearTextButtonAction(_ sender: Any) {
        twTextView.clearText()
    }
    
    // Action to post a tweet, with authorization
    @IBAction func postTweetAction(_ sender: Any) {
        Task {
            await authorizeAndGetToken()
        }
    }
    
    // Asynchronously authorize and obtain a token to post tweets
    private func authorizeAndGetToken() async {
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        let authDomain = "api.twitter.com"
        let authorizationUrl = "https://\(authDomain)/oauth/authorize"
        let tokenUrl = "https://\(authDomain)/oauth/token"
        
        let consumerKey = "b8ja6swBKS7zxeZAgch5uJLJh"
        let consumerSecret = "6DbkZ0dYXVpHJU5nCSN0zCZXwGeUgYhuwjzaNa1paqlGKoAIDw"
        let redirectUrl = "\(bundleId)://\(authDomain)/ios/\(bundleId)/callback"
        let scope = "tweet.read tweet.write"
        let state = generateRandomString(length: 30)
        
        // Initialize OAuth2Swift with Twitter app credentials
        let oauthswift = OAuth2Swift(
            consumerKey: consumerKey,
            consumerSecret: consumerSecret,
            authorizeUrl: authorizationUrl,
            accessTokenUrl: tokenUrl,
            responseType: "code"
        )
        
        guard let codeVerifier = generateCodeVerifier() else { return }
        guard let codeChallenge = generateCodeChallenge(codeVerifier: codeVerifier) else { return }
        
        // Authorize with OAuth and obtain the token
        oauthswift.authorize(
            withCallbackURL: redirectUrl,
            scope: scope,
            state: state,
            codeChallenge: codeChallenge,
            codeChallengeMethod: "S256",
            codeVerifier: codeVerifier
        ) { result in
            switch result {
            case .success(let (credential, _, _)):
                // Successful authorization, post the tweet
                Task {
                    await self.postTweet(authToken: credential.oauthToken)
                }
            case .failure(let error):
                print("Authorization failed:", error.localizedDescription)
            }
        }
    }
    
    // Asynchronously post a tweet with the given authorization token
    private func postTweet(authToken: String) async {
        let postTweetPath = "2/tweets"
        let headers = ["Authorization": "Bearer \(authToken)"]
        
        Task {
            do {
                // Perform the network request to post the tweet
                let result: Result<TweetResponse, NetworkError> = try await networkService.performRequest(
                    endPoint: postTweetPath,
                    method: .post,
                    header: headers
                )
                
                switch result {
                case .success(let tweet):
                    print("Tweet posted:", tweet.data.text)
                    
                case .failure(let error):
                    print("Failed to post tweet:", error.localizedDescription)
                }
            } catch {
                print("Error during network call:", error.localizedDescription)
            }
        }
    }
    
    // Generate a random string of the specified length
    private func generateRandomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
}

// Extension for handling text changes in the text editor
extension TwitterCharactersCounterViewController: TWTextEditorViewDelegate {
    
    func textDidChange(_ textView: UITextView) {
        // Update character count and remaining characters labels
        typedCharactersLabel.text = "\(twTextView.typedCharactersCount)/\(twTextView.maxCountOfCharacters)"
        remainingCharactersLabel.text = "\(twTextView.remainingCharactersCount)"
    }
}
