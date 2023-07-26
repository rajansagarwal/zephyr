import UIKit
import MultipeerConnectivity
import UIKit
import Contacts
import SwiftUI

private let reuseIdentifier = "ImageCell"

class ViewController: UICollectionViewController, MCBrowserViewControllerDelegate, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate {
    
    var intro: [String] = ["Offline? ➡️", "Good. ➡️", ""]
    var currentIndex = 2
    var images = [UIImage]()
    let imageViewTag = 1000
    var peerRoles = [MCPeerID: String]()
    var userRole: String?
    var newNote: String?
    var shouldHide = false
    var messageString = ["Message"]
    var personString = [""]
    
    private let mcServiceType = "zephyr"
    private var mcPeerID = MCPeerID(displayName: UIDevice.current.name)
    private var mcSession: MCSession?
    private var mcNearbyServiceAdvertiser: MCNearbyServiceAdvertiser?
    
    var currentMessageIndex = 0
    var scrollView: UIScrollView!
    var messageLabels: [UILabel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Zephyr"
        title = "Zephyr"
        
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(scrollView)
        
        var messageX: CGFloat = 0
        for message in intro {
            let messageFrame = CGRect(x: messageX, y: 0, width: view.bounds.width, height: view.bounds.height)
            let messageLabel = UILabel(frame: messageFrame)
            messageLabel.textAlignment = .center
            messageLabel.text = message
            scrollView.addSubview(messageLabel)
            messageLabels.append(messageLabel)
            messageX += view.bounds.width
        }
        
        scrollView.contentSize = CGSize(width: messageX, height: view.bounds.height)
        
        let subheaderLabel = UILabel(frame: CGRect(x: 15, y: view.bounds.height, width: view.bounds.width, height: 30))
        subheaderLabel.text = "Received Images"
        subheaderLabel.textAlignment = .left
        view.addSubview(subheaderLabel)
        
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(handleImageSelectionButtonTapped)),
            UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(handleSendMessageButtonTapped))
        ]
        
        navigationItem.leftBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(handleShowConnectionPromtButtonTapped)),
            UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(handleShowConnectionPeersButtonTapped))
        ]
        
        
        navigationItem.setHidesBackButton(true, animated: false)
        navigationItem.title = ""
        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = false }
        navigationItem.leftBarButtonItems?.forEach { $0.isEnabled = false }
        
        mcSession = MCSession(peer: mcPeerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession?.delegate = self
    }
    
    func updateLabelWithMessageString() {
        var yPosition: CGFloat = 150
        
        for (i, message) in messageString.enumerated() {
            let label = UILabel(frame: CGRect(x: 15, y: yPosition, width: view.bounds.width - 30, height: 30))
            label.text = personString[i] + message
            label.textAlignment = .left
            view.addSubview(label)
            
            // Update the vertical position for the next chat message
            yPosition += 40 // You can adjust this value to set the spacing between chat messages
            
            // Check if there's an image available for the current message
            if i < images.count {
                let imageView = UIImageView(frame: CGRect(x: 15, y: yPosition, width: 100, height: 100))
                imageView.image = images[i] // Assuming "images" is an array of UIImage objects
                view.addSubview(imageView)
                
                // Update the vertical position for the next image
                yPosition += 120 // You can adjust this value to set the spacing between images and chat messages
            }
        }
    }
    
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let maxIndex = 3
        let newIndex = Int(scrollView.contentOffset.x / scrollView.bounds.width)
        
        if newIndex != currentMessageIndex {
            currentMessageIndex = newIndex
            showCurrentMessage()
        }
        
        if currentMessageIndex == intro.count - 1 {
            navigationItem.setHidesBackButton(false, animated: true)
            navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = true }
            navigationItem.leftBarButtonItems?.forEach { $0.isEnabled = true }
            intro[0] = ""
            intro[1] = ""
            updateLabelWithMessageString()
            shouldHide = false
        }
        
        if currentMessageIndex >= intro.count - maxIndex {
            shouldHide = true
        } else {
            shouldHide = false
        }
        if currentMessageIndex >= 3 {
            scrollView.isScrollEnabled = false
        } else {
            scrollView.isScrollEnabled = true
        }
    }
    
    func showCurrentMessage() {
        let message = intro[currentMessageIndex]
        messageLabels[currentMessageIndex].text = message
        
        
        if currentMessageIndex == 3 {
            let buttonTitles = ["Join or Host a Network", "Your Network", "Send a Message", "Send an Image"]
            let buttonWidth: CGFloat = 200
            let buttonHeight: CGFloat = 50
            let spacing: CGFloat = 20
            let startY = view.bounds.height/1.4 - (buttonHeight + spacing)/2 * CGFloat(buttonTitles.count)
            
            for (index, title) in messageString.enumerated() {
                let button = UIButton(type: .system)
                button.setTitle(title, for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: 20)
                button.frame = CGRect(x: view.bounds.width/2 - buttonWidth/2, y: startY + (buttonHeight + spacing) * CGFloat(index), width: buttonWidth, height: buttonHeight)
                if title == "Join or Host a Network" {
                    button.addTarget(self, action: #selector(handleShowConnectionPromtButtonTapped), for: .touchUpInside)
                } else if title == "Your Network" {
                    button.addTarget(self, action: #selector(handleShowConnectionPeersButtonTapped), for: .touchUpInside)
                } else if title == "Send a Message" {
                    button.addTarget(self, action: #selector(handleSendMessageButtonTapped), for: .touchUpInside)
                } else if title == "Send an Image" {
                    button.addTarget(self, action: #selector(handleImageSelectionButtonTapped), for: .touchUpInside)
                }
                view.addSubview(button)
            }
        }
    }
    
    @objc func handleButtonTap(_ sender: UIButton) {
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update scroll view content offset to show current message
        scrollView.contentOffset = CGPoint(x: CGFloat(currentMessageIndex) * scrollView.bounds.width, y: 0)
    }
    
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        
        guard let imageView = cell.viewWithTag(imageViewTag) as? UIImageView else { return UICollectionViewCell() }
        
        imageView.image = images[indexPath.item]
        
        let maxImages = 4
        
        if images.count > maxImages {
            images.removeLast()
        }
        
        collectionView.reloadData()
        
        return cell
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .notConnected:
            DispatchQueue.main.async { [weak self] in
                let ac = UIAlertController(title: "Disconnected!", message: "Device \(peerID.displayName) is disconnected", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .cancel))
                
                self?.present(ac, animated: true)
                DispatchQueue.main.async { [weak self] in
                    self?.navigationItem.title = "Zephyr"
                }
            }
        case .connecting:
            print("Connecting: \(peerID.displayName)")
        case .connected:
            print("Connected: \(peerID.displayName)")
            self.userRole = ""
            DispatchQueue.main.async { [weak self] in
                self?.navigationItem.title = "Connected"
            }
        @unknown default:
            print("Unknown state: \(peerID.displayName)")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            if let image = UIImage(data: data) {
                self?.images.insert(image, at: 0)
                // self?.collectionView.insertItems(at: [IndexPath(item: 0, section: 0)])
            } else if let message = String(data: data, encoding: .utf8) {
                self?.messageString += [message]
                self?.personString += [peerID.displayName + ": "]
            }
            self!.updateLabelWithMessageString()
        }
    }
    
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
        guard let mcSession = mcSession else { return }
        invitationHandler(true, mcSession)
    }
    
    private func sendImageToPeers(_ image: UIImage) {
        guard
            let pngImage = image.pngData()
        else {
            return
        }
        
        sendDataToPeers(data: pngImage)
        self.updateLabelWithMessageString()
    }
    
    @objc func handleProfilePromptPressed() {
        var name = ""
        var email = ""
        var phoneNumber = ""
        
        let alertController = UIAlertController(title: "Profile Information", message: "Please enter your personal information", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "Name"
        }
        alertController.addTextField { textField in
            textField.placeholder = "Email"
            textField.keyboardType = .emailAddress
        }
        alertController.addTextField { textField in
            textField.placeholder = "Phone Number"
            textField.keyboardType = .phonePad
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { action in
            name = alertController.textFields?[0].text ?? ""
            email = alertController.textFields?[1].text ?? ""
            phoneNumber = alertController.textFields?[2].text ?? ""
            UserDefaults.standard.setValue(name, forKey: "name")
            UserDefaults.standard.setValue(email, forKey: "email")
            UserDefaults.standard.setValue(phoneNumber, forKey: "phoneNumber")
        }
        
        let userContact = CNMutableContact()
        userContact.givenName = name
        userContact.emailAddresses = [CNLabeledValue(
            label: CNLabelEmailiCloud,
            value: String(email) as NSString)]
        userContact.phoneNumbers = [CNLabeledValue(
            label: CNLabelPhoneNumberMain,
            value: CNPhoneNumber(stringValue: "555-555-1212"))]
        
        // Convert the CNContact object to vCard data
        let contactData = try! CNContactVCardSerialization.data(
            with: [userContact])
    }
    
    @objc private func handleShowConnectionPromtButtonTapped() {
        guard let mcSession = mcSession else {
            let ac = UIAlertController(title: "No session", message: "You have to create or join a session first.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(ac, animated: true)
            return
        }
        
        let ac = UIAlertController(title: "Connect ...", message: nil, preferredStyle: .alert)
        
        ac.addAction(UIAlertAction(title: "Host a session", style: .default, handler: hostASession))
        
        ac.addAction(UIAlertAction(title: "Join a session", style: .default, handler: { [weak self] _ in
            let browser = MCBrowserViewController(serviceType: self?.mcServiceType ?? "", session: mcSession)
            browser.delegate = self
            self?.present(browser, animated: true)
        }))
        
        present(ac, animated: true)
    }
    
    @objc private func hostASession(_ action: UIAlertAction) {
        mcNearbyServiceAdvertiser = MCNearbyServiceAdvertiser(peer: mcPeerID, discoveryInfo: nil, serviceType: mcServiceType)
        mcNearbyServiceAdvertiser?.delegate = self
        mcNearbyServiceAdvertiser?.startAdvertisingPeer()
    }
    
    @objc private func joinASession(_ action: UIAlertAction) {
        guard let mcSession = mcSession else { return }
        
        let mcBrowser = MCBrowserViewController(serviceType: mcServiceType, session: mcSession)
        
        mcBrowser.delegate = self
        
        present(mcBrowser, animated: true, completion: nil)
    }
    
    @objc private func handleSendMessageButtonTapped(_ action: UIAlertAction) {
        let ac = UIAlertController(title: "Send a message", message: nil, preferredStyle: .alert)
        ac.addTextField { textField in
            textField.placeholder = "Enter your message here"
        }
        ac.addAction(UIAlertAction(title: "Send", style: .default, handler: { [weak self, weak ac] _ in
            guard let message = ac?.textFields?[0].text else { return }
            self?.sendMessageToOthers(message)
            self?.messageString += [message]
            self?.personString += [UIDevice.current.name + ": "]
            self!.updateLabelWithMessageString()
        }))
        
        present(ac, animated: true)
    }
    
    private func sendMessageToOthers(_ message: String) {
        sendDataToPeers(data: Data(message.utf8))
        self.updateLabelWithMessageString()
    }
    
    
    private func sendDataToPeers(data: Data) {
        guard
            let mcSession = mcSession
        else {
            return
        }
        
        let connectedPeers = mcSession.connectedPeers
        if connectedPeers.count > 0 {
            do {
                try mcSession.send(data, toPeers: connectedPeers, with: .reliable)
                self.title = "Zephyr"
            } catch {
                let ac = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                
                present(ac, animated: true)
            }
        }
    }
    
    
    @objc private func handleShowConnectionPeersButtonTapped() {
        guard let mcSession = mcSession else {
            return
        }
        
        var peerNames = [String]()
        
        for peer in mcSession.connectedPeers {
            if let role = userRole {
                peerNames.append("\(peer.displayName) - \(role)\n")
            } else {
                peerNames.append("\(peer.displayName)")
            }
        }
        
        var peerNameList = "Your network is empty. Connect with peers to build it."
        
        if !peerNames.isEmpty {
            peerNameList = peerNames.joined(separator: ", ")
        }
        
        let ac = UIAlertController(title: "Your Network", message: peerNameList, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Ok", style: .cancel))
        
        present(ac, animated: true)
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let editingImage = info[.editedImage] as? UIImage else { return }
        
        dismiss(animated: true)
        
        images.insert(editingImage, at: 0)
        // collectionView.insertItems(at: [IndexPath(item: 0, section: 0)])
        
        sendImageToPeers(editingImage)
    }
    
    @objc private func handleImageSelectionButtonTapped() {
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        imagePicker.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        
        present(imagePicker, animated: true)
    }
}
