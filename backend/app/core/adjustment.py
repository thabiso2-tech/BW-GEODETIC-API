import numpy as np

def adjust_3d_baselines(points_dict, baselines):
    """
    Performs 3D Least Squares Adjustment on GNSS Baselines.
    points_dict: {pt_id: [x, y, z, is_fixed]}
    baselines: [{from: id, to: id, dx: val, dy: val, dz: val, var_matrix: []}]
    """
    n_obs = len(baselines) * 3
    n_params = len(points_dict) * 3
    
    A = np.zeros((n_obs, n_params))
    L = np.zeros(n_obs)
    P = np.eye(n_obs) # Weight matrix (ideally from full covariance)

    # Map point IDs to matrix indices
    idx_map = {pid: i for i, pid in enumerate(points_dict.keys())}
    
    for i, b in enumerate(baselines):
        row = i * 3
        f_idx, t_idx = idx_map[b['from']], idx_map[b['to']]
        
        # Design Matrix A (Partial derivatives for 3D vectors)
        A[row:row+3, f_idx*3:f_idx*3+3] = -np.eye(3)
        A[row:row+3, t_idx*3:t_idx*3+3] = np.eye(3)
        
        # Misclosure Vector L = Observed - (Approx_To - Approx_From)
        approx_dx = points_dict[b['to']][0] - points_dict[b['from']][0]
        approx_dy = points_dict[b['to']][1] - points_dict[b['from']][1]
        approx_dz = points_dict[b['to']][2] - points_dict[b['from']][2]
        
        L[row] = b['dx'] - approx_dx
        L[row+1] = b['dy'] - approx_dy
        L[row+2] = b['dz'] - approx_dz

    # Constrain Fixed Points (Eliminate rows/cols for fixed points)
    fixed_indices = [idx_map[pid]*3 + d for pid, val in points_dict.items() if val[3] for d in range(3)]
    
    # Solve Normal Equations: X = (At P A)^-1 At P L
    N = A.T @ P @ A
    U = A.T @ P @ L
    
    # Apply constraints by setting rows/cols to 0 and diagonal to 1 for fixed points
    for idx in fixed_indices:
        N[idx, :] = 0; N[:, idx] = 0; N[idx, idx] = 1; U[idx] = 0
    
    corrections = np.linalg.solve(N, U)
    return corrections.reshape(-1, 3)