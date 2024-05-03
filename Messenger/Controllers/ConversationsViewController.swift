//
//  ViewController.swift
//  Messenger
//
//  Created by Ritik Srivastava on 11/10/20.
//  Copyright © 2020 Ritik Srivastava. All rights reserved.
//

import UIKit
import Firebase

struct Converstaion {
    let id : String
    let name : String
    let otherUserId :  String
    let latestMessage : LatestMessage
}

struct LatestMessage {
    let date : String
    let text : String
    let isRead  : Bool
}

class ConversationsViewController: UIViewController  {
    
    private var conversation = [Converstaion]()
    
    private let tableView : UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(ConversationTableViewCell.self ,
                       forCellReuseIdentifier: ConversationTableViewCell.identifier)
        return table
    }()
    
    private let noConversationLabel : UILabel = {
        let label = UILabel()
        label.text = "no chats are found!"
        label.textColor = .gray
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 21 , weight: .medium)
        label.isHidden = true
        return label
    }()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setting up the tableview
        setupTableView()
        
        //fetching the chats
        fetchConversation()
        
        //add bar button
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(newChat))
        
        // to hide lines in table view
        tableView.separatorColor = UIColor.clear
        
        view.addSubview(tableView)
        view.addSubview(noConversationLabel)
       
        // getting updated on listen any new message
        startListeningForConversation()
        
    }
    
    override func viewDidLayoutSubviews() {
       super.viewWillLayoutSubviews()
        
        tableView.frame = CGRect(x: 0, y: 0, width: view.width , height: view.height)
        tableView.backgroundColor =  UIColor(hex: "#c3e3e8")
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loginCheck()
        tableView.reloadData()
    }
    
    @objc private func newChat(){
        let vc = NewConversationViewController()
        vc.completion = { result in
            self.createUser(result: result)
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav , animated: true)
        print("New chat available")
    }
    
    func createUser(result : [String:String]){
        
        guard let uid = result["uid"] , let name = result["name"] else { return }
        
        let vc = ChatViewController(with: uid, conId: nil)
        vc.title = name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func loginCheck(){
        
        if Auth.auth().currentUser == nil {
            let vc  = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav,animated: false)
        }
        
    }

}

//MARK: here we setup the table view all functionality
extension ConversationsViewController :  UITableViewDelegate, UITableViewDataSource {
        
    func setupTableView(){
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversation.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell  = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier,
                                                  for: indexPath) as! ConversationTableViewCell
        
        // to fill value at correct place
        cell.configure(with: conversation[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        print("table view did select at")
        let convey = conversation[indexPath.row]
        let vc = ChatViewController(with : convey.otherUserId , conId : convey.id)
        vc.title = convey.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
}


//MARK: here we fetch the chat
extension ConversationsViewController {
    
    func fetchConversation(){
        tableView.isHidden = false
    }
    
    
    func startListeningForConversation(){
        
        guard let uniqueId = Helper.uniqueId() else { return }
        
        DatabaseManager.shared.getAllConversation(for: uniqueId) {[weak self] (result) in
            
            guard let strongSelf = self else { return }
            
            switch result {
            case .failure(let error):
                print("New error in listen chat \(error)")
            case .success(let conversation):
                
                guard !conversation.isEmpty else {  return  }
                self?.conversation = conversation
                
                DispatchQueue.main.async {
                    strongSelf.tableView.reloadData()
                }
            }
        }
        
    }
}
