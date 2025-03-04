//
//  TopicDetailView.swift
//  V2exOS
//
//  Created by isaced on 2022/7/24.
//

import SwiftUI
import V2exAPI
import MarkdownUI

struct TopicDetailView: View {
  
  @EnvironmentObject private var currentUser: CurrentUserStore
  
  var topic: V2Topic
  
  @State var commentList: [V2Comment]?
  @State var page = 0
  @State var commentEnd = false
  @State var isCommentLoading = false
  
  func hasMoreComments() -> Bool {
    return currentUser.user != nil && (commentEnd || commentList?.count ?? 0 < topic.replies ?? 0)
  }
  
  var body: some View {
    List {
      VStack(alignment: .leading, spacing: 5) {
        Text(topic.title ?? "" )
          .font(.title)
          .lineLimit(3)
        
        HStack(alignment: .bottom, spacing: 20) {
          
          if let authorName = topic.member?.username {
            HStack(alignment: .bottom, spacing: 5) {
              Image(systemName: "person.circle")
              UserName(authorName)
            }
          }
          
          HStack(alignment: .bottom, spacing: 5) {
            Image(systemName: "clock")
            if let created = topic.created {
              Text(Date(timeIntervalSince1970: TimeInterval(created)).fromNow())
            }
          }
          Link(destination: URL(string: "https://www.v2ex.com/t/\(topic.id)")!) {
            Image(systemName: "safari")
            Text("在网页中打开")
          }
          
        }.foregroundColor(Color(NSColor.secondaryLabelColor))
        
        Spacer()
        
        Markdown(topic.content ?? "")
          .font(.body)
          .fixedSize(horizontal: false, vertical: true)
      }
      
      Spacer()
      
      CommentListView(commentCount: topic.replies, commentList: commentList)
      
      if hasMoreComments() {
        Spacer()
        HStack {
          Spacer()
          ProgressView()
            .onAppear {
              loadComments(page: page + 1)
            }
          Spacer()
        }
      }
    }
    .foregroundColor(Color(NSColor.labelColor))
    .task {
      loadComments(page: 1)
    }
  }
  
  func loadComments(page: Int) {
    if isCommentLoading {
      return
    }
    isCommentLoading = true
    
    Task {
      do {
        let res = try await v2ex.replies(topicId: topic.id, page: page)
        self.page = page
        if page <= 1 {
          commentList = res?.result
        }else{
          if let list = res?.result {
            if !hasMoreComments() {
              isCommentLoading = false
              return
            }
            
            commentList?.append(contentsOf: list)
            // 到底了
            if list.count == 0 {
              commentEnd = true
            }
          }
        }
      } catch {
        commentEnd = true
        print(error)
      }
      
      isCommentLoading = false
    }
  }
}

struct TopicDetailView_Previews: PreviewProvider {
  static var previews: some View {
    TopicDetailView(topic: PreviewData.topic,
                    commentList: [
                      PreviewData.comment,
                      PreviewData.comment,
                      PreviewData.comment
                    ])
    .previewLayout(.fixed(width: 300, height: .infinity))
  }
}

