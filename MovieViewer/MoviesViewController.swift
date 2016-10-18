//
//  MoviesViewController.swift
//  MovieViewer
//
//  Created by Bryce Aebi on 10/12/16.
//  Copyright © 2016 Bryce Aebi. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {

    @IBOutlet weak var networkError: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    var movies: [NSDictionary]?
    var endpoint: String!
    let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
    
    func refreshControlAction(refreshControl: UIRefreshControl) {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        dataLoader(completionHandler: {
            (dataOrNil, response, error) in
            self.tableView.reloadData()
            
            MBProgressHUD.hide(for: self.view, animated: true)
            
            if let data = dataOrNil {
                if let responseDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                    self.movies = responseDictionary["results"] as! [NSDictionary]
                    self.tableView.reloadData()
                    refreshControl.endRefreshing()
                }
            }
        })
    }
    
    // Sets up the movie fetching code, takes a custom callback
    func dataLoader(completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        if isInternetAvailable() {
            networkError.isHidden = true
            let url = URL(string: "https://api.themoviedb.org/3/movie/\(endpoint!)?api_key=\(apiKey)")
            let request = URLRequest(url: url!)
            let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: request, completionHandler: completionHandler)
            task.resume()
        } else {
            networkError.isHidden = false
        }
    }
    
    func isInternetAvailable() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return (isReachable && !needsConnection)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        
        networkError.superview!.bringSubview(toFront: networkError)

        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        dataLoader(completionHandler: {
            (dataOrNil, response, error) in
            self.tableView.reloadData()
            
            MBProgressHUD.hide(for: self.view, animated: true)
            
            if let data = dataOrNil {
                if let responseDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                    self.movies = responseDictionary["results"] as! [NSDictionary]
                    self.tableView.reloadData()
                }
            }
        })
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlAction(refreshControl:)), for: UIControlEvents.valueChanged)
        tableView.insertSubview(refreshControl, at: 0)
        
    }
    
   
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let movies = movies {
            return movies.count
        } else {
            return 0
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell
        
        let movie = movies![indexPath.row]
        let title = movie["title"] as! String
        let overview = movie["overview"] as! String
        
        if let posterPath = movie["poster_path"] as? String {
            let baseUrl = "https://image.tmdb.org/t/p/w500"
            let imageUrl = URL(string: baseUrl + posterPath)
            cell.posterView.setImageWith(imageUrl!)
        }
        
        cell.titleLabel.text = title
        cell.overviewLabel.text = overview
        cell.overviewLabel.sizeToFit()
        return cell
    }

    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let cell = sender as! UITableViewCell
        let indexPath = tableView.indexPath(for: cell)
        let movie = movies![indexPath!.row]
        
        let detailViewController = segue.destination as! DetailViewController
        detailViewController.movie = movie
    }

}
