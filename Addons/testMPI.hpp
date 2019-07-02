/*
 * Copyright (c) 2017, Miroslav Stoyanov
 *
 * This file is part of
 * Toolkit for Adaptive Stochastic Modeling And Non-Intrusive ApproximatioN: TASMANIAN
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions
 *    and the following disclaimer in the documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse
 *    or promote products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * UT-BATTELLE, LLC AND THE UNITED STATES GOVERNMENT MAKE NO REPRESENTATIONS AND DISCLAIM ALL WARRANTIES, BOTH EXPRESSED AND IMPLIED.
 * THERE ARE NO EXPRESS OR IMPLIED WARRANTIES OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE, OR THAT THE USE OF THE SOFTWARE WILL NOT INFRINGE ANY PATENT,
 * COPYRIGHT, TRADEMARK, OR OTHER PROPRIETARY RIGHTS, OR THAT THE SOFTWARE WILL ACCOMPLISH THE INTENDED RESULTS OR THAT THE SOFTWARE OR ITS USE WILL NOT RESULT IN INJURY OR DAMAGE.
 * THE USER ASSUMES RESPONSIBILITY FOR ALL LIABILITIES, PENALTIES, FINES, CLAIMS, CAUSES OF ACTION, AND COSTS AND EXPENSES, CAUSED BY, RESULTING FROM OR ARISING OUT OF,
 * IN WHOLE OR IN PART THE USE, STORAGE OR DISPOSAL OF THE SOFTWARE.
 */

#include "TasmanianAddons.hpp"
#include "tasgridCLICommon.hpp"

/*!
 * \brief Check if the points in the two grids match bit-wise.
 */
inline bool checkPoints(TasGrid::TasmanianSparseGrid const &gridA, TasGrid::TasmanianSparseGrid const &gridB){
    if (gridA.getNumPoints()     != gridB.getNumPoints())     return false;
    if (gridA.getNumDimensions() != gridB.getNumDimensions()) return false;
    auto pA = gridA.getPoints();
    auto pB = gridB.getPoints();
    double err = 0.0;
    for(auto x = pA.begin(), y = pB.begin(); x != pA.end(); x++, y++) err += std::abs(*x - *y);
    return (err == 0.0); // bit-wise match is reasonable to expect here, but use with caution for some grids
}

/*!
 * \brief Simple test of MPI Send/Recv of sparse grids, binary and ascii formats.
 */
template<bool use_binary>
bool testSendReceive(){
    auto true_grid = TasGrid::makeGlobalGrid(5, 3, 4, TasGrid::type_level, TasGrid::rule_clenshawcurtis);

    int me, tag_size = 0, tag_data = 1;
    MPI_Comm_rank(MPI_COMM_WORLD, &me);
    if (me == 0){
        return (TasGrid::MPIGridSend<use_binary>(true_grid, 1, tag_size, tag_data, MPI_COMM_WORLD) == MPI_SUCCESS);
    }else if (me == 1){
        MPI_Status status;
        TasGrid::TasmanianSparseGrid grid;
        auto result = TasGrid::MPIGridRecv<use_binary>(grid, 0, tag_size, tag_data, MPI_COMM_WORLD, &status);
        if (result != MPI_SUCCESS) return false;
        return checkPoints(true_grid, grid);
    }else{
        return true;
    }
}

/*!
 * \brief Simple test of MPI Send/Recv of sparse grids, binary and ascii formats.
 */
template<bool use_binary>
bool testBcast(){
    auto true_grid = TasGrid::makeGlobalGrid(5, 1, 4, TasGrid::type_level, TasGrid::rule_clenshawcurtis);

    int me;
    MPI_Comm_rank(MPI_COMM_WORLD, &me);
    if (me == 1){ // using proc 1 to Bcast the grid
        return (TasGrid::MPIGridBcast<use_binary>(true_grid, 1, MPI_COMM_WORLD) == MPI_SUCCESS);
    }else{
        TasGrid::TasmanianSparseGrid grid;
        auto result = TasGrid::MPIGridBcast<use_binary>(grid, 1, MPI_COMM_WORLD);
        if (result != MPI_SUCCESS) return false;
        return checkPoints(true_grid, grid);
    }
}