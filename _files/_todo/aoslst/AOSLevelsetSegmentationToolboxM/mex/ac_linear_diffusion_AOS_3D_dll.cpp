#include "mex.h"
#include <exception>

#define DEBUG

#define PRINT_MACRO(str, p, N) \
    mexPrintf("%s", str); \
    for(int ii = 0; ii<N; ii++) mexPrintf("%f, ", p[ii]); \
    mexPrintf("\n"); 

void ac_tridiagonal_Thomas_decomposition(double* alpha, double* beta, double* gamma, 
										 double* l, double* m, double* r, unsigned long N);

void ac_tridiagonal_Thomas_solution(double* l, double* m, double* r, double* d, 
									double* y, unsigned long N);

template< class T>
class C3DImage
{
    public:
        int m_dims[3]; // [row, column, plane]
    private:
        T*  m_pV; 
        int m_plane_size;
    public:
        C3DImage(T* pV, const int* dims) : m_pV(pV)
        {
            for(int i = 0; i< 3; i++) m_dims[i] = dims[i]; 
            m_plane_size = m_dims[0]*m_dims[1];
        }
        
        void GetColon1(double* p, int idx1, int idx2) // (:,idx1,idx2)
        {
            int len = m_dims[0]; 
            T* pV = &(m_pV[idx1*m_dims[0]+idx2*m_plane_size]);
            for(int i = 0; i<len; i++)
            {
                p[i] = (double)(*pV);
                pV ++; 
            }
        }
        
        void SetColon1(double* p, int idx1, int idx2)
        {
            int len = m_dims[0]; 
            T* pV = &(m_pV[idx1*m_dims[0]+idx2*m_plane_size]);
            for(int i = 0; i<len; i++)
            {
                *pV = p[i];
                pV ++; 
            }
        }
        
        void AddColon1(double* p, int idx1, int idx2)
        {
            int len = m_dims[0]; 
            T* pV = &(m_pV[idx1*m_dims[0]+idx2*m_plane_size]);
            for(int i = 0; i<len; i++)
            {
                *pV = *pV + p[i];
                pV ++; 
            }
        }
        
        void GetColon2(double* p, int idx1, int idx2) // (idx1,:,idx2)
        {
            int len = m_dims[1];
            T* pV = &(m_pV[idx1+idx2*m_plane_size]); 
            for(int i = 0; i<len; i++)
            {
                p[i] = (double)(*pV); 
                pV += m_dims[0]; 
            }
        }
        
        void SetColon2(double* p, int idx1, int idx2)
        {
            int len = m_dims[1];
            T* pV = &(m_pV[idx1+idx2*m_plane_size]); 
            for(int i = 0; i<len; i++)
            {
                *pV = p[i]; 
                pV += m_dims[0]; 
            }
        }
        
        void AddColon2(double* p, int idx1, int idx2)
        {
            int len = m_dims[1];
            T* pV = &(m_pV[idx1+idx2*m_plane_size]); 
            for(int i = 0; i<len; i++)
            {
                *pV = *pV + p[i]; 
                pV += m_dims[0]; 
            }
        }
        
        void GetColon3(double* p, int idx1, int idx2) // (idx1,idx2,:)
        {
            int len = m_dims[2];
            T* pV = &(m_pV[idx1+idx2*m_dims[0]]); 
            for(int i = 0; i<len; i++)
            {
                p[i] = (double)(*pV); 
                pV += m_plane_size; 
            }
        }
        
        void SetColon3(double* p, int idx1, int idx2)
        {
            int len = m_dims[2];
            T* pV = &(m_pV[idx1+idx2*m_dims[0]]); 
            for(int i = 0; i<len; i++)
            {
                *pV = p[i];
                pV += m_plane_size; 
            }
        }
        
        void AddColon3(double* p, int idx1, int idx2)
        {
            int len = m_dims[2];
            T* pV = &(m_pV[idx1+idx2*m_dims[0]]); 
            for(int i = 0; i<len; i++)
            {
                *pV = *pV + p[i];
                pV += m_plane_size; 
            }
        }
};

void div_AOS_1D(double delta_t, int len, // input
    // because this functinon is called repeatedly by outside, so it's better 
    // to let the caller manages the memory of the following variables
    double* alpha, double *gamma, // inputs
    double* L, double *M, double *R) // outputs
{  
    double s = 9*delta_t; 
    
    gamma[0] = -s;
    alpha[0] = 3 - gamma[0];
    for(int i = 1; i < len-1; i++)
    {
        gamma[i] = -s;
        alpha[i] = 3 - (gamma[i-1] + gamma[i]); 
    }
    alpha[len-1] = 3 - gamma[len-2]; 
    ac_tridiagonal_Thomas_decomposition(alpha, gamma, gamma, 
        L, M, R, len);       
}

#define NEW_MACRO(x)          \
    L = new double[x-1];      \
    M = new double[x];        \
    R = new double[x-1];      \
    alpha = new double[x];    \
    gamma = new double[x-1];  \
    d = new double[x];        \
    out = new double[x]; 

#define DELETE_MACRO    \
    delete []alpha;     \
    delete []gamma;     \
    delete []L;         \
    delete []M;         \
    delete []R;         \
    delete []d;         \
    delete []out;

template< class T > 
void linear_diffusion_AOS(T& g, double delta_t, C3DImage<double>& g_n)
{
    int j, k; 
    double *d, *out, *L, *M, *R; 
    double *alpha, *beta, *gamma; 
    
    // Along the plane direction. 
    NEW_MACRO(g.m_dims[2]);
    div_AOS_1D(delta_t, g.m_dims[2], alpha, gamma, L, M, R);  
    for(j = 0; j < g.m_dims[0]; j++)
    {
        for(k = 0; k < g.m_dims[1]; k++)
        {
//             PRINT_MACRO(" L : ", L, g.m_dims[2]-1);
//             PRINT_MACRO(" M : ", M, g.m_dims[2]);
//             PRINT_MACRO(" R : ", R, g.m_dims[2]-1);
            g.GetColon3(d, j, k); 
            ac_tridiagonal_Thomas_solution(L, M, R, d, out, g.m_dims[2]);
            g_n.SetColon3(out, j, k);
        }
    }
    DELETE_MACRO;
    
    // Along the column direction. 
    NEW_MACRO(g.m_dims[1]);
    div_AOS_1D(delta_t, g.m_dims[1],alpha, gamma, L, M, R);  
    for(j = 0; j < g.m_dims[0]; j++)
    {
        for(k = 0; k < g.m_dims[2]; k++)
        {
            g.GetColon2(d, j, k); 
            ac_tridiagonal_Thomas_solution(L, M, R, d, out, g.m_dims[1]);
            g_n.AddColon2(out, j, k);
        }
    }
    DELETE_MACRO;
    
    // Along the row direction. 
    NEW_MACRO(g.m_dims[0]);
    div_AOS_1D(delta_t, g.m_dims[0],alpha, gamma, L, M, R);  
    for(j = 0; j < g.m_dims[1]; j++)
    {
        for(k = 0; k < g.m_dims[2]; k++)
        {
            g.GetColon1(d, j, k); 
            ac_tridiagonal_Thomas_solution(L, M, R, d, out, g.m_dims[0]);
            g_n.AddColon1(out, j, k);
        }
    }
    DELETE_MACRO;
}

void mexFunction(
	int nlhs,              // Number of left hand side (output) arguments
	mxArray *plhs[],       // Array of left hand side arguments
	int nrhs,              // Number of right hand side (input) arguments
	const mxArray *prhs[]  // Array of right hand side arguments
)
{    
    // linear_diffusion_AOS_3D_dll(V, delta_t)
    const int *dims = mxGetDimensions(prhs[0]);   // dimensions of input
    double delta_t = mxGetScalar(prhs[1]); 
    
    // Generate output.
    plhs[0] = mxCreateNumericArray(3, dims, mxDOUBLE_CLASS, mxREAL);
    C3DImage<double> g_n(mxGetPr(plhs[0]), dims);
    
    // feature map type 
    mxClassID g_type = mxGetClassID(prhs[0]);
    switch(g_type)
    {
        case mxINT8_CLASS:
        {
    		C3DImage<char> g((char*)mxGetPr(prhs[0]), dims);
            linear_diffusion_AOS(g, delta_t, g_n);
            break;
        }
        case mxUINT8_CLASS:
        {
    		C3DImage<unsigned char> g((unsigned char*)mxGetPr(prhs[0]), dims);
            linear_diffusion_AOS(g, delta_t, g_n);
            break;
        }
        case mxINT16_CLASS:
        {
    		C3DImage<short> g((short*)mxGetPr(prhs[0]), dims);
            linear_diffusion_AOS(g, delta_t, g_n);
            break;
        }
        case mxUINT16_CLASS:
        {
    		C3DImage<unsigned short> g((unsigned short*)mxGetPr(prhs[0]), dims);
            linear_diffusion_AOS(g, delta_t, g_n);
            break;
        }
        case mxINT32_CLASS:
        {
    		C3DImage<int> g((int*)mxGetPr(prhs[0]), dims);
            linear_diffusion_AOS(g, delta_t, g_n);
            break;
        }
        case mxUINT32_CLASS:
        {
    		C3DImage<unsigned int> g((unsigned int*)mxGetPr(prhs[0]), dims);
            linear_diffusion_AOS(g, delta_t, g_n);
            break;
        }
        case mxSINGLE_CLASS:
        {
    		C3DImage<float> g((float*)mxGetPr(prhs[0]), dims);
            linear_diffusion_AOS(g, delta_t, g_n);
            break;
        }
        case mxDOUBLE_CLASS:       
        {
    		C3DImage<double> g((double*)mxGetPr(prhs[0]), dims);
            linear_diffusion_AOS(g, delta_t, g_n);
            break;
        }
    }
} 

void ac_tridiagonal_Thomas_decomposition(double* alpha, double* beta, double* gamma, 
										 double* l, double* m, double* r, unsigned long N)
{
	m[0] = alpha[0];
	for(unsigned long int i=0; i<N-1; i++)
	{
		r[i] = beta[i];
		l[i] = gamma[i]/m[i];
		m[i+1] = alpha[i+1] - l[i]*beta[i];
	}
}

void ac_tridiagonal_Thomas_solution(double* l, double* m, double* r, double* d, 
									double* y, unsigned long N)
{
	unsigned long i,idx;
	double *yy = new double[N];
    
	// forward
	yy[0] = d[0];
	for( i = 1; i<N; ++i)
		yy[i] = d[i] - l[i-1]*yy[i-1];

	// backward
	y[N-1] = yy[N-1]/m[N-1];
	for( i = N-1; i > 0; i--)
	{
		idx = i-1;
		y[idx] = (yy[idx] - r[idx]*y[idx+1])/m[idx];
	}

	delete [] yy;
}
