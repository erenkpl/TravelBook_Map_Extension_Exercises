//
//  ListViewController.swift
//  TravelBook
//
//  Created by Eren on 24.08.2024.
//

import UIKit
import CoreData

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    var titleArray = [String]()
    var idArray = [UUID]()
    var choosenTitle = ""
    var choosenTitleId : UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonClicked)) //Sağ üst köşeye '+' butonu eklemek için.
        
        // TableView ayarları.
        tableView.delegate = self
        tableView.dataSource = self
        
        getData()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("newPlace"), object: nil)
    }
    
    @objc func getData() {
        
        // CoreData
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        // Fetch Request
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        request.returnsObjectsAsFaults = false
        
        do {
            let results = try context.fetch(request)
            
            if results.count > 0 {
                
                self.titleArray.removeAll(keepingCapacity: false)
                self.idArray.removeAll(keepingCapacity: false)
                
                // Results dizisindeki objelerden, title ve id'lerini alarak, objenin diğer viewControllerda gösterilecek bilgilerini alabileceğiz.
                for result in results as! [NSManagedObject] {
                    if let title = result.value(forKey: "title") as? String {
                        self.titleArray.append(title)
                    }
                    if let id = result.value(forKey: "id") as? UUID {
                        self.idArray.append(id)
                    }
                    
                    tableView.reloadData()
                }
            }
        }
        catch {
            print("Request Error!")
        }
        
    }
    
    @objc func addButtonClicked() {
        
        // Ekleme butonuna basıldığında seçilmiş yer stringimizi boş hale getiriyoruz ki viewController'a boş bilgilerle gidip doldurabilelim.
        choosenTitle = ""
        performSegue(withIdentifier: "toViewController", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { //TableView'da kaç satır olduğu.
        return titleArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { //TableView'daki satırlarda ne görüneceği.
        let cell = UITableViewCell()
        cell.textLabel?.text = titleArray[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // TableView'da satır seçildiğinde, seçilmiş satırın bilgilerini aktarıyoruz.
        choosenTitle = titleArray[indexPath.row]
        choosenTitleId = idArray[indexPath.row]
        performSegue(withIdentifier: "toViewController", sender: nil)
        
    }
    
    // Ekranlar Arası Bilgi Paylaşımı.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toViewController" {
            let destinationVC = segue.destination as! ViewController
            destinationVC.selectedTitle = choosenTitle
            destinationVC.selectedTitleID = choosenTitleId
            
        }
    }

}
