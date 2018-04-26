//
//  ViewController.swift
//  Twig
//
//  Created by Luka Kerr on 25/4/18.
//  Copyright © 2018 Luka Kerr. All rights reserved.
//

import Cocoa
import Highlightr
import Down

let DEFAULT_FONT = NSFont(name: "Courier", size: CGFloat(18))

class MarkdownViewController: NSViewController, NSTextViewDelegate {

  @IBOutlet var markdownTextView: NSTextView!
  
  public let highlightr = Highlightr()!
  
  // Cocoa binding for text inside markdownTextView
  @objc var attributedMarkdownTextInput: NSAttributedString {
    get {
      return NSAttributedString(string: markdownTextView.string)
    }
    set {
      syntaxHighlight(newValue.string)
      generatePreview(newValue.string)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Setup notification observer for theme change
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.themeChanged),
      name: NSNotification.Name(rawValue: "changeThemeNotification"),
      object: nil
    )
    
    markdownTextView.delegate = self
    markdownTextView.font = DEFAULT_FONT
    markdownTextView.insertionPointColor = .gray
  }
  
  override func viewDidAppear() {
    highlightr.setTheme(to: theme.syntax)
    setBackgroundColor()
  }
  
  override var acceptsFirstResponder: Bool {
    return true
  }
  
  @IBAction func togglePreview(sender: NSMenuItem) {
    if let splitViewController = self.parent as? NSSplitViewController,
      let previewViewController = splitViewController.splitViewItems.last {
      previewViewController.collapseBehavior = .preferResizingSplitViewWithFixedSiblings
      previewViewController.animator().isCollapsed = !previewViewController.isCollapsed
    }
  }
  
  // Syntax highlight the given markdown string and insert into text view
  private func syntaxHighlight(_ string: String) {
    highlightr.setTheme(to: theme.syntax)
    let highlightedCode = highlightr.highlight(string, as: "markdown")
    let cursorPosition = markdownTextView.selectedRanges[0].rangeValue.location
    
    if let syntaxHighlighted = highlightedCode {
      let code = NSMutableAttributedString(attributedString: syntaxHighlighted)
      if let font = DEFAULT_FONT {
        code.withFont(font)
      }
      markdownTextView.textStorage?.beginEditing()
      markdownTextView.textStorage?.setAttributedString(code)
      markdownTextView.textStorage?.endEditing()
    }
    markdownTextView.setSelectedRange(NSMakeRange(cursorPosition, 0))
  }
  
  private func generatePreview(_ string: String) {
    if let splitViewController = self.parent as? NSSplitViewController,
      let previewView = splitViewController.splitViewItems.last {
      let previewViewController = previewView.viewController as? PreviewViewController
      let down = Down(markdownString: string)
      let html = try? down.toHTML()
      if let html = html {
        previewViewController?.webPreview.loadHTMLString(html, baseURL: nil)
      }
    }
  }
  
  // On theme change, update window appearance and reparse with possible new syntax
  @objc private func themeChanged(notification: Notification?) {
    syntaxHighlight(markdownTextView.string)
    setBackgroundColor()
  }
  
  private func setBackgroundColor() {
    guard let color = highlightr.theme.themeBackgroundColor else {
      return
    }
    
    if color.isDark {
      self.view.window?.appearance = NSAppearance(named: .vibrantDark)
    } else {
      self.view.window?.appearance = NSAppearance(named: .vibrantLight)
    }
    self.view.window?.backgroundColor = color
  }

}
