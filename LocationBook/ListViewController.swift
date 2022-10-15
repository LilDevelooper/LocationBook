//
//  ListViewController.swift
//  LocationBook
//
//  Created by yunus emre vural on 12.10.2022.
//

import UIKit
import CoreData

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var nameArray = [String]()
    var noteArray = [String]()
    var idArray = [UUID]()
    
    //Yeni bir kayıt mı yoksa seçilen satırı mı göster ?
    var selectedName = ""
    var selectedID : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addButton))
        
        tableView.delegate = self
        tableView.dataSource = self
        
        getData()
        
    }
    
    
    @objc func addButton(){
        selectedName = ""
        performSegue(withIdentifier: "toViewController", sender: nil)
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nameArray.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        var content = cell.defaultContentConfiguration()
        
        content.text = nameArray[indexPath.row]
        content.secondaryText = noteArray[indexPath.row]
        
        cell.contentConfiguration = content
        
        return cell
    }
    
    override func viewWillAppear(_ animated: Bool) {
            NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name(rawValue: "newData"), object: nil)
        }
        
    
  @objc func getData(){
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let context = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Locations")
        
        fetchRequest.returnsObjectsAsFaults = false
        
        do{
            let results = try context.fetch(fetchRequest)
            
            if results.count > 0 {
                
                self.nameArray.removeAll(keepingCapacity: false)
                self.idArray.removeAll(keepingCapacity: false)
                self.noteArray.removeAll(keepingCapacity: false)
                
                for result in results as! [NSManagedObject] {
                    if let name = result.value(forKey: "name") as? String{
                        self.nameArray.append(name)
                    }
                    
                    if let note = result.value(forKey: "note") as? String{
                        self.noteArray.append(note)
                    }
                    
                    if let id = result.value(forKey: "id") as? UUID{
                        
                        self.idArray.append(id)
                    }
                }
            }
            
            self.tableView.reloadData()
            
            
        }catch{
            print("error")
        }
    }
    
    
    //Diğer view controller' e veri aktar.
    //Yeni bir kayıt mı yoksa seçilen satırı mı göster ?
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        selectedName = nameArray[indexPath.row]
        selectedID   = idArray[indexPath.row]
        performSegue(withIdentifier: "toViewController", sender: nil)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toViewController" {
            
            let destinationVC = segue.destination as! ViewController
            
            destinationVC.selectedName = selectedName
            destinationVC.selectedId   = selectedID
            
        }
    }
    
    
    //Delete row from CoreData
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
                
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Locations")
                
                let idString = idArray[indexPath.row].uuidString
                
                fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
                
                fetchRequest.returnsObjectsAsFaults = false
                
                do {
                    
                    let results = try context.fetch(fetchRequest)
                    if results.count > 0 {
                        
                        for result in results as! [NSManagedObject] {
                            
                            if let id = result.value(forKey: "id") as? UUID {
                                
                                if id == idArray[indexPath.row] {
                                    context.delete(result)
                                    nameArray.remove(at: indexPath.row)
                                    idArray.remove(at: indexPath.row)
                                    self.tableView.reloadData()
                                    
                                    do {
                                        try context.save()
                                        
                                    } catch {
                                        print("error")
                                    }
                                    
                                    break
                                    
                                }
                                
                            }
                            
                        }
                        
                    }
                } catch {
                    print("error")
                }
                
            }
            
        }
        
    
}
