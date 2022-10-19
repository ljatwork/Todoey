//
//  ViewController.swift
//  Todoey
//
//  Created by Philipp Muellauer on 02/12/2019.
//  Copyright © 2019 App Brewery. All rights reserved.
//

import UIKit
import RealmSwift
import ChameleonFramework

class TodoListViewController: SwipeTableViewController {
    
    var itemArray: Results<Item>?
    @IBOutlet weak var searchBar: UISearchBar!
    let realm = try! Realm()
    var selectedCategory : Category? {
        didSet{
            loadItems()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = selectedCategory?.name
        searchBar.barTintColor = FlatWatermelon()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemArray?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if let item = itemArray {
            cell.textLabel?.text = item[indexPath.row].title
            let percentage = CGFloat(indexPath.row) / CGFloat(item.count)
            if let bgColor = FlatWatermelon().darken(byPercentage: percentage) {
                cell.backgroundColor = bgColor
                cell.textLabel?.textColor = ContrastColorOf(bgColor, returnFlat: true)
            }
        } else {
            cell.textLabel?.text = "No items added yet"
            let bgColor = FlatWatermelon()
            cell.backgroundColor = bgColor
            cell.textLabel?.textColor = ContrastColorOf(bgColor, returnFlat: true)
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let item = itemArray?[indexPath.row] {
            do {
                try realm.write{
                    // realm.delete(item)
                    item.done = !item.done
                }
            } catch {
                debugPrint("Error updating, \(error)")
            }
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }

    @IBAction func addItemPressed(_ sender: UIBarButtonItem) {
        
        var textField = UITextField()
        let alert = UIAlertController(title: "Add New Item", message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: "Add Item", style: .default) { [weak self] (action) in
            guard let self = `self` else { return }
            if let value = textField.text {
                let item = Item()
                item.title = value
                item.dateCreated = Date()
                self.saveItems(item)
            }
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Create new item"
            textField = alertTextField
        }
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    override func updateModel(at indexPath: IndexPath) {
        if let item = itemArray?[indexPath.row] {
            do {
                try realm.write{
                    realm.delete(item)
                }
            } catch {
                debugPrint("\(error)")
            }
        }
    }
}

//MARK: CoreData
extension TodoListViewController {
    func saveItems(_ item: Item) {
        if let currentCategory = self.selectedCategory {
            do {
                try self.realm.write {
                    currentCategory.items.append(item)
                }
            } catch {
                print("Error saving new items, \(error)")
            }
            tableView.reloadData()
        }
    }
    
    func loadItems() {
        itemArray = selectedCategory?.items.sorted(byKeyPath: "title", ascending: true)
        tableView.reloadData()
    }
}

extension TodoListViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchValue = searchBar.text, !searchValue.isEmpty {
            itemArray = itemArray?.filter("title CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "title", ascending: true)
            tableView.reloadData()
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            loadItems()
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        }
    }
}
