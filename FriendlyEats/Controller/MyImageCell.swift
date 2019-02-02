import UIKit
import Eureka

/// Definition of a custom cell
public final class MyImageCell: PushSelectorCell<UIImage> {
    
    /// xib outlets
    @IBOutlet weak public var myImageView: UIImageView!
    @IBOutlet weak var myLabel: UILabel!
    
    /// Required inits
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        fatalError("init(style:reuseIdentifier:) has not been implemented")
    }
    
    /// Override the setup to change the cell height
    public override func setup() {
        super.setup()
        
        height = { return 100 }
        
        myImageView.image = UIImage(named: "book_placeholder")
       
    }
    
    /// Cell update - The image selected in the row will appear in the imageView (outlet)
    public override func update() {
        super.update()
        
        if let image = row.value {
            myImageView.image = image
        }
        
        myLabel.text = row.title
        textLabel?.text = nil
        detailTextLabel?.text = nil
    }
    
}
