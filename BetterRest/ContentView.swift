//
//  ContentView.swift
//  BetterRest
//
//  Created by Aaron Brown on 9/29/23.
//

import CoreML
import SwiftUI

struct ContentView: View {
    
    @State private var wakeUp: Date = defaultWakeTime
    @State private var wakeUpEvening: Date = eveningWakeTime
    @State private var sleepAmount: Double = 8.0
    @State private var coffeeAmount: Int = 1
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false
    @State private var eveningShift = false
    
    static var defaultWakeTime: Date {
        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date.now
    }
    
    static var eveningWakeTime: Date {
        var components = DateComponents()
        components.hour = 18
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date.now
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    DatePicker("Please enter a time",selection: eveningShift ? $wakeUpEvening : $wakeUp , displayedComponents: .hourAndMinute)
                        .labelsHidden()
                } header: {
                    Text("When do you want to wake up?")
                        .font(.headline)
                }
                
                Section {
                    Stepper("\(sleepAmount.formatted()) hours", value: $sleepAmount, in: 4...12, step: 0.25)
                } header: {
                    Text("Desired amount of sleep")
                        .font(.headline)
                }
                Section {
                    Stepper("\(coffeeAmount.formatted()) \(coffeeAmount <= 1 ? "cup" : "cups")", value: $coffeeAmount, in: 1...12, step: 1)
                } header: {
                    Text("Daily coffee intake")
                        .font(.headline)
                }
                Section {
                    HStack {
                        Spacer()
                        Toggle("Evening Worker", isOn: $eveningShift)
                            .labelsHidden()
                    }
                } header: {
                    Text("Evening Shift")
                        .font(.headline)
                }
            }
            .navigationTitle("Better Rest")
            .toolbar {
                Button("Calculate", action: calculateBedtime)
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") {
                    sleepAmount = 8.0
                    coffeeAmount = 1
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    func calculateBedtime () {
        do {
            let config = MLModelConfiguration()
            let model = try SleepCalculator(configuration: config)
            
            let components = Calendar.current.dateComponents([.hour, .minute], from: eveningShift ? wakeUpEvening : wakeUp)
            let hour = (components.hour ?? 0) * 60 * 60
            let minute = (components.minute ?? 0) * 60
            
            let prediction = try model.prediction(wake: Double(hour + minute), estimatedSleep: sleepAmount, coffee: Double(coffeeAmount))
            
            let sleepTime = (eveningShift ? wakeUpEvening : wakeUp) - prediction.actualSleep
            alertTitle = "Your ideal bedtime is..."
            alertMessage = sleepTime.formatted(date: .omitted, time: .shortened)
        } catch {
            alertTitle = "Error"
            alertMessage = "Sorry, there was an error calculating your sleep."
        }
        return showingAlert.toggle()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

