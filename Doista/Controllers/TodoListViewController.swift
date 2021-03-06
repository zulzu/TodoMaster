//
//  ViewController.swift
//  Doista
//
//  Created by Andras Pal on 22/04/2019.
//  Copyright © 2019 Andras Pal. All rights reserved.
//

import UIKit
import RealmSwift

class TodoListViewController: SwipeTableViewController {
    
    var todoItems: Results<Item>?
    let realm = try? Realm()
    
    var selectedCategory : Category? {
        didSet{
            loadItems()
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        title = selectedCategory?.name
        guard let colourHex = selectedCategory?.color  else { fatalError()}
        updateNavBar(withHexCode: colourHex)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.textMainColour]
        navigationController?.navigationBar.barTintColor = UIColor.background01
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.textMainColour as Any]
    }
    
    //MARK: - Nav Bar Setup Methods
    func updateNavBar(withHexCode colourHexCode: String){
        guard let navBar = navigationController?.navigationBar else { fatalError(String.getString(.errorMsg))}
        
        let navBarColour = UIColor(hex: selectedCategory!.color)
        navBar.tintColor = navBarColour?.withAlphaComponent(0.7)
        navBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : navBarColour?.withAlphaComponent(0.7) as Any]
        navBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : navBarColour as Any]
    }
    
    //MARK: - Tableview Datasource Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoItems?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        if let item = todoItems?[indexPath.row] {
            
            cell.textLabel?.text = item.title
            
            let itemNumber : CGFloat = CGFloat((indexPath.row + 1))
            var itemAlpha : CGFloat = (1.0 - ((itemNumber * 3)/100))
            
            if itemAlpha < 0.61 {
                itemAlpha = 0.61
            }
            
            cell.backgroundColor = UIColor(hex: selectedCategory!.color)?.withAlphaComponent(itemAlpha)
            
            cell.textLabel?.textColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 0.9)
            
            if item.isCompleted == false {
                cell.textLabel?.attributedText =  nil
                cell.textLabel?.text =  item.title
            } else {
                cell.textLabel?.attributedText = item.title.strikeThrough()
            }
            
        } else {
            cell.textLabel?.text = String.getString(.noItems)
        }
        
        return cell
    }
    
    //MARK: - TableView Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let item = todoItems?[indexPath.row] {
            do {
                try realm?.write {
                    item.isCompleted = !item.isCompleted
                }
            } catch {
                print("Error saving completed status, \(error)")
            }
        }
        
        tableView.reloadData()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - Add New Items
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        
        var textField = UITextField()
        let alert = UIAlertController(title: String.getString(.addItem), message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: String.getString(.add), style: .default) { (action) in
            
            if let currentCategory = self.selectedCategory {
                do {
                    try self.realm?.write {
                        let newItem = Item()
                        newItem.itemID = Item.incrementalIDItem()
                        newItem.title = textField.text!
                        newItem.dateCreated = Date()
                        currentCategory.items.append(newItem)
                    }
                } catch {
                    print("Error savig new items, \(error)")
                }
            }
            self.tableView.reloadData()
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = String.getString(.itemName)
            textField = alertTextField
        }
        
        createAlert(alert: alert, action: action)
    }
    
    //MARK - Model Manipulation Methods
    func loadItems() {
        
        todoItems = selectedCategory?.items.sorted(byKeyPath: "dateCreated", ascending: true)
        tableView.reloadData()
    }
    
    //MARK: Delete Data From Swipe
    override func updateModel(at indexPath: IndexPath) {
        if let item = todoItems?[indexPath.row] {
            do {
                try realm?.write {
                    realm?.delete(item)
                }
            } catch {
                print("Error deleting item, \(error)")
            }
        }
        tableView.reloadData()
    }
    
    //MARK: Edit Data From Swipe
    override func editModel(at indexPath: IndexPath) {
        
        var textField = UITextField()
        let updatedItem = self.todoItems?[indexPath.row]
        let alert = UIAlertController(title: String.getString(.editItem), message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: String.getString(.update), style: .default) { (action) in
            
            if self.selectedCategory?.items != nil {
                do {
                    try self.realm?.write {
                        updatedItem?.title = textField.text!
                        self.realm?.add(updatedItem!, update: .all)
                    }
                } catch {
                    print("Error savig new items, \(error)")
                }
            }
            
            self.tableView.reloadData()
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = String.getString(.newName)
            textField = alertTextField
        }
        
        createAlert(alert: alert, action: action)
    }
}
