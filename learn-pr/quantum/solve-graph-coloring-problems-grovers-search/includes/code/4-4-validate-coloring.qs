﻿namespace ExploringGroversSearchAlgorithm {
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Intrinsic;


    operation MarkColorEquality (c0 : Qubit[], c1 : Qubit[], target : Qubit) : Unit is Adj+Ctl {
        within {
            for ((q0, q1) in Zip(c0, c1)) {
                // compute XOR of bits q0 and q1 in place (storing it in q1)
                CNOT(q0, q1);
            }
        } apply {
            // if all computed XORs are 0, the bit strings are equal
            (ControlledOnInt(0, X))(c1, target);
        }
    }


    operation MarkValidVertexColoring (
        edges : (Int, Int)[], 
        colorsRegister : Qubit[], 
        target : Qubit
    ) : Unit is Adj+Ctl {
        let nEdges = Length(edges);
        // Allocate one extra qubit per edge to mark the edges that connect vertices with the same color
        using (conflictQubits = Qubit[nEdges]) {
            within {
                for (((start, end), conflictQubit) in Zip(edges, conflictQubits)) {
                    // Extract the parts of the qubit register that that store the colors of the endpoints
                    let startColorRegister = colorsRegister[start * 2 .. start * 2 + 1];
                    let endColorRegister = colorsRegister[end * 2 .. end * 2 + 1];
                    // Check that the endpoints have different colors: apply MarkColorEquality operation; 
                    // if the colors are the same, the result will be 1, indicating a conflict
                    MarkColorEquality(startColorRegister, endColorRegister, conflictQubit);
                }
            } apply {
                // If there are no conflicts (all qubits are in 0 state), the vertex coloring is valid
                (ControlledOnInt(0, X))(conflictQubits, target);
            }
        }
    }


    @EntryPoint()
    operation ShowColoringValidationCheck () : Unit {
        // Graph description: hardcoded from the example
        let nVertices = 5;
        let edges = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (3, 4)];

        // Graph coloring: hardcoded from the example
        let coloring = [false, false, true, false, false, true, true, true, false, true];

        using ((coloringRegister, target) = (Qubit[2 * nVertices], Qubit())) {
            // Encode the coloring in the quantum register:
            // apply an X gate to each qubit that corresponds to "true" bit in the bit string
            ApplyPauliFromBitString(PauliX, true, coloring, coloringRegister);

            // Apply the operation that will check whether the coloring is valid
            MarkValidVertexColoring(edges, coloringRegister, target);

            // Print validation result
            let isColoringValid = M(target) == One;
            Message($"The coloring is {isColoringValid ? "valid" | "invalid"}");

            // Return the qubits to |0⟩ state before releasing them.
            ResetAll(coloringRegister);
        }
    }
}