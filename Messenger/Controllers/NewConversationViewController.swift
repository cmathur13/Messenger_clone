//
//  NewConversationViewController.swift
//  Messenger
//
//  Created by Ritik Srivastava on 11/10/20.
//  Copyright © 2020 Ritik Srivastava. All rights reserved.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController  {

    private let spinner = JGProgressHUD()
    
    //this is a closure which can acess from which this viewcontroller is intiated and help top send value
    public var completion : (([String:String] )->(Void))?
    
    private let searchBar : UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search user here ... "
        return searchBar
    }()
    
    private let tableView : UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(newConversationCell.self, forCellReuseIdentifier: "newConversationCell")
        return table
    }()
    
    private let noResult : UILabel = {
       let label = UILabel()
        label.isHidden = true
        label.text = "No user found!"
        label.textColor = .gray
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()
    
    private var users : [[String : String]] = [[String:String]]()
    private var results : [[String : String]] = [[String:String]]()
    
    private var hasFetched = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar.delegate = self
        
        navigationController?.navigationBar.topItem?.titleView = searchBar
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelSearch))
        
        searchBar.becomeFirstResponder()
        
        view.backgroundColor = .white
        
        //setting up table view
        setupTableView()
        
        view.addSubview(tableView)
        view.addSubview(noResult)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.frame = view.bounds
        
        noResult.frame = CGRect(x: view.width/4 , y: view.height, width: view.width/2, height: 200)
    }

}

extension NewConversationViewController : UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        guard let text = searchBar.text , !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        
        results.removeAll()
        
        spinner.show(in: view)
        self.searchUsers(query: text)
    }
    
    
    func searchUsers(query: String){
        //check if array is firebase reuslt
        if hasFetched{
            // if it does filter
            self.filterUser(with: query)
        }
        else{
            //if not fetch the filter
            DatabaseManager.shared.getAllUser { (result) in
                
                switch result {
                case .failure(let error):
                    print(error)
                case .success(let users):
                    self.hasFetched = true
                    self.users = users
                    self.filterUser(with: query)
                }
            }
            
        }
        
        //update the UI
    }
    
    func filterUser(with term : String){
        
        guard let myId = Helper.uniqueId() else { return }
        
        //update the ui or show no reuslt label
        guard hasFetched else { return }

        let results : [[String : String]] = self.users.filter({
            
            guard let id = $0["uid"] , myId != id else { return false }
            
            guard let name = $0["name"]?.lowercased() else { return false}
            
            return name.hasPrefix(term.lowercased())
            
        })

        self.results = results
        self.spinner.dismiss()
        
        print("call update UI",results.count)
        updateUI()
    }
    
    func updateUI(){
        if results.isEmpty {
            print("no result")
            self.noResult.isHidden = false
            self.tableView.isHidden = true
        }else{
            self.noResult.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
            print(self.results)
        }
    }
    
    @objc private func cancelSearch(){
        dismiss(animated: true, completion: nil)
    }
 
}


extension NewConversationViewController : UITableViewDelegate ,UITableViewDataSource {
    
    func setupTableView(){
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "newConversationCell" , for: indexPath) as! newConversationCell
        
//        cell.textLabel?.text = results[indexPath.row]["name"]
        
        cell.configure(with: results[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        //start new conversation
        let targetUserData = results[indexPath.row]
        dismiss(animated: true) { [weak self] in
            guard let strongSelf = self else {return }
            strongSelf.completion?(targetUserData)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 95
    }
}
