//
//  InfoView.swift
//  H2Oe
//
//  Created by Christina Moser on 12.01.26.
//

import SwiftUI

struct InfoView: View {
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    
                    header
                    floodBehaviorCard
                    emergencyCard
                    sourcesCard
                    
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .navigationTitle("Info")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(Color.cyan.opacity(0.15), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Flood safety")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Quick, structured tips for flooding situations in Austria. Always follow official warnings and local authorities.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 2)
    }
    
    
    private var floodBehaviorCard: some View {
        infoCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("What to do:")
                    .font(.subheadline)
                    .padding(.bottom, 8)
                
                bulletRow(
                    icon: "doc.text.fill",
                    title: "Move essentials upstairs",
                    text: "Bring important documents (e.g., insurance papers, passport), valuables, food, laundry, etc. to higher floors."
                )
                
                bulletRow(
                    icon: "door.left.hand.closed",
                    title: "Secure doors and windows",
                    text: "Barricade doors and windows in areas that may be flooded."
                )
                
                bulletRow(
                    icon: "bolt.slash.fill",
                    title: "Switch off electricity and heating",
                    text: "Turn off power in threatened areas and shut down the heating system."
                )
                
                bulletRow(
                    icon: "cylinder.fill",
                    title: "Secure tanks and lines",
                    text: "Secure oil tanks, gas lines, and telephone lines."
                )
                
                bulletRow(
                    icon: "water.waves",
                    title: "Seal sewer openings",
                    text: "Close sewer openings and weigh them down if possible."
                )
                
                bulletRow(
                    icon: "cup.and.saucer.fill",
                    title: "Do not drink tap or well water",
                    text: "Avoid drinking tap water or private well water—it may be contaminated."
                )
            }
        }
    }
    
    private var emergencyCard: some View {
        infoCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Emergency numbers:")
                    .font(.subheadline)
                    .padding(.bottom, 8)
                
                emergencyRow(number: "112", title: "EU emergency number")
                emergencyRow(number: "122", title: "Fire brigade")
                emergencyRow(number: "133", title: "Police")
                emergencyRow(number: "144", title: "Ambulance / Rescue")
            }
        }
    }
    
    private var sourcesCard: some View {
        infoCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Sources:")
                    .font(.subheadline)
                    .padding(.bottom, 8)
                
                Group{
                    
                    Text("Data used in this app:")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Link(
                            "Lower Austria Open Government Data – Data catalog",
                            destination: URL(string: "https://www.noe.gv.at/noe/Open-Government-Data/Datenkatalog.html")!
                        )
                        .font(.footnote)
                        
                        Spacer()
                        Link(
                            "GeoSphere Austria",
                            destination: URL(string: "https://www.geosphere.at/de")!
                        )
                        .font(.footnote)
                    }
                }
            
                Spacer()
                
                Group{
                    
                    Text("Further information in case of emergencies:")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Link(
                            "Austria.gv.at emergencies & disasters",
                            destination: URL(string: "https://www.oesterreich.gv.at/de/themen/notfaelle_unfaelle_und_kriminalitaet/katastrophenfaelle/1/Seite.29500323")!
                        )
                        .font(.footnote)
                    }
                }
            }
        }
    }
    
    
    private func infoCard(@ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.separator, lineWidth: 0.5)
        )
    }
    
    
    private func bulletRow(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.cyan)
                .frame(width: 22)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(text)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private func emergencyRow(number: String, title: String) -> some View {
        HStack {
            HStack(spacing: 10) {
                Text(number)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.cyan.opacity(0.85))
                    )
                
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    InfoView()
}

