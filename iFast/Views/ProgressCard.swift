//
//  ProgressCard.swift
//  iFast
//
//  Created by Kalaiselvan Ulaganathan on 8/11/25.
//
import SwiftUI

struct ProgressCard: View {
    let title: String
    let progress: Double
    let color: Color
    let subtitle: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(subtitle ?? "\(Int(progress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
