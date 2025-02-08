# **Lab 7: Design of Local Binary Pattern Facial Recognition System**  

## **1. Introduction**  
This lab focuses on implementing a **Local Binary Pattern (LBP) Facial Recognition System**.  
Students will integrate multiple components, including **CLBP, HCU, Comparator, Controller, and DCU**, to build a complete recognition system.  

---

## **2. System Architecture**  

### **External Block Diagram**  
*(Insert Fig.2 - System block diagram here)*  

### **Internal Block Diagram**  
*(Insert Fig.3 - Internal system block diagram here)*  

The system consists of several key modules:  
- **TOP Module**: Main module integrating all submodules.  
- **CLBP (Completed Local Binary Pattern)**: Computes the local binary pattern for facial image data.  
- **HCU (Histogram Computation Unit)**: Generates histograms from CLBP data.  
- **Comparator**: Compares input histograms with stored histograms to identify the closest match.  
- **Controller**: Manages different states of the system (training, prediction, comparison).  
- **DCU (Distance Computation Unit)**: Calculates the distance metric for facial recognition.  

---

## **3. System Operation Flow**  

### **Training Mode**  
1. Receive **gridX** and **gridY** signals.  
2. Compute **Local Binary Pattern (LBP)** values and store them in **RAM_LBP**.  
3. Compute **histogram information** from **RAM_LBP** and store in **HIST_RAM_TRAIN**.  
4. Repeat steps **(2) ~ (3)** until **prediction mode** is triggered.  

### **Prediction Mode**  
1. Compute histogram information from **RAM_LBP** and store in **HIST_RAM_PREDICT**.  
2. The **Comparator** begins computation.  
3. **DCU computes the distance (D)** between the test image and training data:  
   \[
   D = \sum_{i=1}^{n} (H_T[i] - H_P[i])^2
   \]
   where **n = 16384 (8×8×256)**.  
4. Repeat **step (3)** for **7×N times**, where **N** is the number of different subjects.  
5. Find the **closest histogram match** in **HIST_RAM_TRAIN**.  
6. Output **label, minDistance, and done signal**.  
7. Repeat steps **(1) ~ (6)** until the **testbench** stops the simulation.  

---

## **4. Module Descriptions**  

### **TOP Module**  
- Integrates all components of the system.  
- Manages communication between different submodules.  

### **CLBP (Completed Local Binary Pattern)**  
- Computes LBP features for the input facial images.  
- Stores results in **RAM_LBP**.  

### **HCU (Histogram Computation Unit)**  
- Computes histograms from the **RAM_LBP** data.  
- Stores the training histograms in **HIST_RAM_TRAIN**.  
- Stores the predicted histograms in **HIST_RAM_PREDICT**.  

### **Comparator**  
- Compares **HIST_RAM_PREDICT** with **HIST_RAM_TRAIN**.  
- Identifies the closest match based on **distance metric (D)**.  

### **DCU (Distance Computation Unit)**  
- Computes the **distance (D)** between test images and training images.  
- Outputs the **minimum distance**.  

### **Controller**  
- **Manages FSM states**:  
  - **Idle**  
  - **Training**  
  - **Prediction**  
  - **Comparison**  
- Controls data flow between components.  

*(Insert FSM state diagram here)*  

---

## **5. Implementation Steps**  

### **Step 1: Design & Implementation**  
- Implement each module separately using **Verilog**.  
- Ensure correct **data communication** between modules.  

### **Step 2: Verification (Simulation & Testing)**  
- Write **testbenches** for each module.  
- Validate outputs against expected results.  
- Ensure correct FSM transitions.  

### **Step 3: Synthesis & Optimization**  
- Synthesize `top.v` with the following constraints:  
  - **Clock period**: ≤ 2.0 ns  
  - **Wire load model**: `N16ADFP_StdCells_s0p72vm40c`  
- Generate **top_syn.v** and apply timing constraints using **top_syn.sdf**.  

### **Step 4: Performance Evaluation**  
- Measure and document:  
  - **Clock period**  
  - **Total cell area**  
  - **Post-simulation time**  
- Ensure **≥ 90% SuperLint Coverage**.  

---

## **6. Simulation & Results**  

### **6.1 Waveforms**  
*(Attach screenshots of simulation waveforms here)*  

### **6.2 SuperLint Coverage (top.v)**  
| Metric      | Value |
|------------|-------|
| Total Lines | XXXX  |
| Warnings    | XXXX  |
| Errors      | XXXX  |
| Coverage (%)| ≥ 90% |

### **6.3 Performance Metrics**  
| Metric              | Value  |
|---------------------|--------|
| Clock Period (ns)   | X.XX   |
| Total Cell Area     | XXXX   |
| Post-Simulation Time | XXXX   |

---

## **7. Lessons Learned & Optimization Techniques**  
- **Reducing Cell Area**: **Resource sharing for registers**.  
- **Shortening Datapath**: **Inserting registers between instances**.  
- **Optimizing Memory Usage**: Efficient storage of **LBP & Histogram data**.  
